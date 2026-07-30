'use strict';
const ExcelJS = require('exceljs');
const path = require('path');
const fs = require('fs');
const moment = require('moment');
const logger = require('../utils/logger');

/**
 * ExcelReporter — Generates Flutter_E2E_Report.xlsx with 4 sheets:
 *   Sheet 1: Summary (Execution stats)
 *   Sheet 2: Test Cases (All results)
 *   Sheet 3: Failed Tests (Failures with screenshot paths)
 *   Sheet 4: Execution Logs (Step-level logs from logger.executionLog)
 */
class ExcelReporter {
  constructor() {
    this.workbook = new ExcelJS.Workbook();
    this.workbook.creator  = 'AgriLink QA Automation';
    this.workbook.created  = new Date();
    this.workbook.modified = new Date();
    this.reportsDir = path.resolve(process.env.REPORT_DIR || './reports');
    if (!fs.existsSync(this.reportsDir)) fs.mkdirSync(this.reportsDir, { recursive: true });
  }

  // ─── Style Helpers ─────────────────────────────────────────

  _headerStyle(bgColor = '1E7D45') {
    return {
      font: { name: 'Calibri', size: 11, bold: true, color: { argb: 'FFFFFFFF' } },
      fill: { type: 'pattern', pattern: 'solid', fgColor: { argb: `FF${bgColor}` } },
      alignment: { horizontal: 'center', vertical: 'middle', wrapText: true },
      border: {
        top: { style: 'thin' }, left: { style: 'thin' },
        bottom: { style: 'thin' }, right: { style: 'thin' },
      },
    };
  }

  _cellStyle(bgColor = 'FFFFFF', textColor = '000000') {
    return {
      font: { name: 'Calibri', size: 10, color: { argb: `FF${textColor}` } },
      fill: { type: 'pattern', pattern: 'solid', fgColor: { argb: `FF${bgColor}` } },
      alignment: { vertical: 'middle', wrapText: true },
      border: {
        top: { style: 'hair' }, left: { style: 'hair' },
        bottom: { style: 'hair' }, right: { style: 'hair' },
      },
    };
  }

  _statusStyle(status) {
    const colors = { PASS: '22C55E', FAIL: 'EF4444', SKIP: 'F59E0B', WARN: 'F97316' };
    const bgColor = colors[status.toUpperCase()] || 'FFFFFF';
    return {
      font: { name: 'Calibri', size: 10, bold: true, color: { argb: 'FFFFFFFF' } },
      fill: { type: 'pattern', pattern: 'solid', fgColor: { argb: `FF${bgColor}` } },
      alignment: { horizontal: 'center', vertical: 'middle' },
    };
  }

  _applyHeaders(sheet, headers) {
    const row = sheet.addRow(headers.map(h => h.title));
    row.height = 30;
    headers.forEach((h, i) => {
      const cell = row.getCell(i + 1);
      Object.assign(cell, { style: this._headerStyle(h.color || '1E7D45') });
      sheet.getColumn(i + 1).width = h.width || 20;
    });
    sheet.getRow(1).freeze = { xSplit: 0, ySplit: 1 };
    sheet.views = [{ state: 'frozen', ySplit: 1 }];
  }

  // ─── Sheet 1: Summary ──────────────────────────────────────

  _buildSummarySheet(stats) {
    const sheet = this.workbook.addWorksheet('📊 Summary', {
      properties: { tabColor: { argb: 'FF1E7D45' } },
    });
    sheet.mergeCells('A1:B1');
    const titleCell = sheet.getCell('A1');
    titleCell.value = '🌾 AgriLink E2E Automation Report';
    titleCell.style = {
      font: { name: 'Calibri', size: 16, bold: true, color: { argb: 'FF1E7D45' } },
      alignment: { horizontal: 'center', vertical: 'middle' },
    };
    sheet.getRow(1).height = 40;
    sheet.addRow([]);

    const rows = [
      ['Execution Date',    moment().format('YYYY-MM-DD HH:mm:ss')],
      ['Device Name',       stats.deviceName || process.env.DEVICE_NAME || 'emulator-5554'],
      ['Android Version',   stats.androidVersion || process.env.PLATFORM_VERSION || '13.0'],
      ['App Package',       process.env.APP_PACKAGE || 'com.agrilink.app'],
      ['Total Tests',       stats.total],
      ['✅ Passed',         stats.passed],
      ['❌ Failed',         stats.failed],
      ['⏭️ Skipped',       stats.skipped],
      ['Pass %',            `${stats.passPercent}%`],
      ['Total Duration',    `${stats.durationSecs}s`],
    ];

    rows.forEach(([label, value]) => {
      const row = sheet.addRow([label, value]);
      row.getCell(1).style = { font: { bold: true }, fill: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE8F5E9' } } };
      row.getCell(2).style = { alignment: { horizontal: 'center' } };
      sheet.getColumn(1).width = 28;
      sheet.getColumn(2).width = 40;
    });
  }

  // ─── Sheet 2: Test Cases ───────────────────────────────────

  _buildTestCasesSheet(testCases) {
    const sheet = this.workbook.addWorksheet('📋 Test Cases', {
      properties: { tabColor: { argb: 'FF3B82F6' } },
    });
    const headers = [
      { title: 'Test ID',   width: 18 },
      { title: 'Module',    width: 18 },
      { title: 'Scenario',  width: 60 },
      { title: 'Status',    width: 12 },
      { title: 'Device',    width: 22 },
      { title: 'Duration',  width: 14 },
    ];
    this._applyHeaders(sheet, headers);

    testCases.forEach((tc, i) => {
      const row = sheet.addRow([
        tc.id || `TC-${String(i + 1).padStart(3, '0')}`,
        tc.module || 'General',
        tc.title,
        tc.status.toUpperCase(),
        process.env.DEVICE_NAME || 'emulator-5554',
        `${tc.durationMs || 0}ms`,
      ]);
      row.height = 22;
      [1, 2, 3, 5, 6].forEach(col => {
        row.getCell(col).style = this._cellStyle(i % 2 === 0 ? 'F9FBF9' : 'FFFFFF');
      });
      row.getCell(4).style = this._statusStyle(tc.status);
    });
  }

  // ─── Sheet 3: Failed Tests ─────────────────────────────────

  _buildFailedTestsSheet(failures) {
    const sheet = this.workbook.addWorksheet('❌ Failed Tests', {
      properties: { tabColor: { argb: 'FFEF4444' } },
    });
    const headers = [
      { title: 'Test Name',         width: 50, color: 'B91C1C' },
      { title: 'Failure Reason',    width: 60, color: 'B91C1C' },
      { title: 'Screenshot Path',   width: 50, color: 'B91C1C' },
      { title: 'Device',            width: 22, color: 'B91C1C' },
      { title: 'Android Version',   width: 18, color: 'B91C1C' },
    ];
    this._applyHeaders(sheet, headers);

    if (failures.length === 0) {
      sheet.addRow(['✅ No failures — all tests passed!', '', '', '', '']);
      return;
    }

    failures.forEach((f, i) => {
      const row = sheet.addRow([
        f.title,
        f.error || 'Unknown error',
        f.screenshotPath || 'N/A',
        process.env.DEVICE_NAME || 'emulator-5554',
        process.env.PLATFORM_VERSION || '13.0',
      ]);
      row.height = 22;
      [1, 2, 3, 4, 5].forEach(col => {
        row.getCell(col).style = this._cellStyle(i % 2 === 0 ? 'FEF2F2' : 'FFF5F5');
      });
    });
  }

  // ─── Sheet 4: Execution Logs ───────────────────────────────

  _buildExecutionLogsSheet(logs) {
    const sheet = this.workbook.addWorksheet('📝 Execution Logs', {
      properties: { tabColor: { argb: 'FF8B5CF6' } },
    });
    const headers = [
      { title: 'Timestamp',   width: 26, color: '5B21B6' },
      { title: 'Test Name',   width: 50, color: '5B21B6' },
      { title: 'Step',        width: 50, color: '5B21B6' },
      { title: 'Result',      width: 12, color: '5B21B6' },
      { title: 'Remarks',     width: 40, color: '5B21B6' },
    ];
    this._applyHeaders(sheet, headers);

    (logs || []).forEach((log, i) => {
      const row = sheet.addRow([
        moment(log.timestamp).format('YYYY-MM-DD HH:mm:ss.SSS'),
        log.testName,
        log.step,
        log.result,
        log.remarks || '',
      ]);
      row.height = 20;
      [1, 2, 3, 5].forEach(col => {
        row.getCell(col).style = this._cellStyle(i % 2 === 0 ? 'F5F3FF' : 'FDFCFF');
      });
      row.getCell(4).style = this._statusStyle(log.result || 'INFO');
    });
  }

  // ─── Main Generate ─────────────────────────────────────────

  /**
   * Generate the full Excel report.
   * @param {{total:number,passed:number,failed:number,skipped:number,durationSecs:number}} stats
   * @param {Array} testCases
   * @param {Array} failures
   * @param {Array} executionLogs
   * @returns {Promise<string>} output file path
   */
  async generate(stats, testCases, failures, executionLogs) {
    stats.passPercent = stats.total > 0
      ? ((stats.passed / stats.total) * 100).toFixed(1)
      : '0.0';

    this._buildSummarySheet(stats);
    this._buildTestCasesSheet(testCases);
    this._buildFailedTestsSheet(failures);
    this._buildExecutionLogsSheet(executionLogs);

    const outPath = path.join(this.reportsDir, 'Flutter_E2E_Report.xlsx');
    await this.workbook.xlsx.writeFile(outPath);
    logger.info(`Excel report generated: ${outPath}`);
    return outPath;
  }
}

module.exports = ExcelReporter;
