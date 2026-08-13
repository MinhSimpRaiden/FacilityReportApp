"use strict";

const admin = require("firebase-admin");
const {logger} = require("firebase-functions");
const {onRequest} = require("firebase-functions/v2/https");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

exports.createReport = onRequest(
  {
    region: "asia-southeast1",
  },
  async (request, response) => {
    if (request.method === "OPTIONS") {
      response.set("Access-Control-Allow-Origin", "*");
      response.set("Access-Control-Allow-Headers", "content-type,x-webhook-secret");
      response.set("Access-Control-Allow-Methods", "POST,OPTIONS");
      response.status(204).send("");
      return;
    }

    if (request.method !== "POST") {
      response.status(405).json({
        success: false,
        error: "Method not allowed. Use POST.",
      });
      return;
    }

    const expectedSecret = process.env.WEBHOOK_SECRET;
    const receivedSecret = request.get("x-webhook-secret");

    if (!expectedSecret) {
      logger.error("WEBHOOK_SECRET is not configured for createReport.");
      response.status(500).json({
        success: false,
        error: "Server webhook secret is not configured.",
      });
      return;
    }

    if (!receivedSecret || receivedSecret !== expectedSecret) {
      logger.warn("Rejected createReport request with invalid webhook secret.");
      response.status(401).json({
        success: false,
        error: "Unauthorized.",
      });
      return;
    }

    try {
      const reportInput = normalizeReportInput(request.body);
      const validationError = validateReportInput(reportInput);

      if (validationError) {
        response.status(400).json({
          success: false,
          error: validationError,
        });
        return;
      }

      const reportData = {
        category: reportInput.category,
        location: reportInput.location,
        description: reportInput.description,
        reporterName: reportInput.reporterName,
        status: "PENDING",
        createdAt: parseCreatedAt(reportInput.createdAt),
        fixedAt: null,
        fixedBy: null,
      };

      const reportRef = await db.collection("reports").add(reportData);
      const tokens = await getDeviceTokens();
      const sentCount = await sendNewReportNotification(tokens, reportData);

      logger.info("Created report and sent notifications.", {
        reportId: reportRef.id,
        sentCount,
      });

      response.status(200).json({
        success: true,
        reportId: reportRef.id,
        sentCount,
      });
    } catch (error) {
      logger.error("createReport failed.", error);
      response.status(500).json({
        success: false,
        error: "Internal server error.",
      });
    }
  },
);

function normalizeReportInput(body) {
  return {
    category: stringOrEmpty(body && body.category),
    location: stringOrEmpty(body && body.location),
    description: stringOrEmpty(body && body.description),
    reporterName: stringOrEmpty(body && body.reporterName),
    status: stringOrEmpty(body && body.status),
    createdAt: body && body.createdAt,
    fixedAt: body && body.fixedAt,
    fixedBy: body && body.fixedBy,
  };
}

function validateReportInput(report) {
  if (!report.category) {
    return "Missing required field: category.";
  }
  if (!report.location) {
    return "Missing required field: location.";
  }
  if (!report.description) {
    return "Missing required field: description.";
  }
  if (!report.reporterName) {
    return "Missing required field: reporterName.";
  }
  return null;
}

function parseCreatedAt(value) {
  if (!value) {
    return admin.firestore.FieldValue.serverTimestamp();
  }

  const parsedDate = new Date(value);
  if (Number.isNaN(parsedDate.getTime())) {
    return admin.firestore.FieldValue.serverTimestamp();
  }

  return admin.firestore.Timestamp.fromDate(parsedDate);
}

async function getDeviceTokens() {
  const snapshot = await db.collection("deviceTokens").get();
  const tokens = [];

  snapshot.forEach((doc) => {
    const data = doc.data() || {};
    const token = typeof data.token === "string" ? data.token.trim() : "";
    if (token) {
      tokens.push(token);
    }
  });

  return [...new Set(tokens)];
}

async function sendNewReportNotification(tokens, report) {
  if (tokens.length === 0) {
    logger.info("No device tokens found. Skipping FCM notification.");
    return 0;
  }

  let sentCount = 0;
  const tokenChunks = chunkArray(tokens, 500);

  for (const tokenChunk of tokenChunks) {
    const message = {
      tokens: tokenChunk,
      notification: {
        title: "Có báo cáo CSVC mới",
        body: `${report.category} - ${report.location}`,
      },
      data: {
        category: report.category,
        location: report.location,
        type: "new_report",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "facility_reports",
        },
      },
    };

    const result = await messaging.sendEachForMulticast(message);
    sentCount += result.successCount;

    result.responses.forEach((sendResult, index) => {
      if (!sendResult.success) {
        logger.warn("Failed to send FCM notification.", {
          token: tokenChunk[index],
          error: sendResult.error && sendResult.error.message,
        });
      }
    });
  }

  return sentCount;
}

function stringOrEmpty(value) {
  return typeof value === "string" ? value.trim() : "";
}

function chunkArray(items, size) {
  const chunks = [];
  for (let index = 0; index < items.length; index += size) {
    chunks.push(items.slice(index, index + size));
  }
  return chunks;
}
