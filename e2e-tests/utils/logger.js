'use strict';
const winston = require('winston');
const DailyRotateFile = require('winston-daily-rotate-file');
const path = require('path');
const fs = require('fs');

const logsDir = path.resolve(process.env.REPORT_DIR || './reports', 'logs');
if (!fs.existsSync(logsDir)) fs.mkdirSync(logsDir, { recursive: true });

const LOG_FORMAT = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
  winston.format.errors({ stack: true }),
  winston.format.printf(({ timestamp, level, message, stack }) => {
    return stack
      ? `[${timestamp}] [${level.toUpperCase()}] ${message}\n${stack}`
      : `[${timestamp}] [${level.toUpperCase()}] ${message}`;
  }),
);

const logger = winston.createLogger({
  level: 'debug',
  format: LOG_FORMAT,
  transports: [
    // ─── Console ────────────────────────────────────────────
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        LOG_FORMAT,
      ),
    }),

    // ─── Daily rotating combined log ────────────────────────
    new DailyRotateFile({
      filename: path.join(logsDir, 'agrilink-e2e-%DATE%.log'),
      datePattern: 'YYYY-MM-DD',
      zippedArchive: false,
      maxFiles: '7d',
      maxSize: '20m',
      level: 'debug',
    }),

    // ─── Error-only log ─────────────────────────────────────
    new DailyRotateFile({
      filename: path.join(logsDir, 'agrilink-errors-%DATE%.log'),
      datePattern: 'YYYY-MM-DD',
      zippedArchive: false,
      maxFiles: '14d',
      level: 'error',
    }),
  ],
  exceptionHandlers: [
    new winston.transports.File({ filename: path.join(logsDir, 'exceptions.log') }),
  ],
  rejectionHandlers: [
    new winston.transports.File({ filename: path.join(logsDir, 'rejections.log') }),
  ],
});

/**
 * Global execution log entries — used for Excel Report Sheet 4.
 * @type {Array<{timestamp:string, testName:string, step:string, result:string, remarks:string}>}
 */
logger.executionLog = [];

/**
 * Appends an entry to the in-memory execution log for Excel reporting.
 */
logger.logStep = (testName, step, result, remarks = '') => {
  const entry = {
    timestamp: new Date().toISOString(),
    testName,
    step,
    result,
    remarks,
  };
  logger.executionLog.push(entry);
  logger.info(`[STEP] [${result}] ${testName} → ${step}${remarks ? ' — ' + remarks : ''}`);
};

module.exports = logger;
