'use strict';
const path = require('path');
const fs = require('fs');
const logger = require('./logger');

/**
 * Screenshot utility — captures screenshots on demand, on failure,
 * and stores them with organized naming under reports/screenshots or reports/failures.
 */
class ScreenshotUtil {
  /**
   * Take a screenshot and save it.
   * @param {WebdriverIO.Browser} driver
   * @param {string} name - Descriptive name for the screenshot (no extension)
   * @param {boolean} isFailure - If true, saves to reports/failures/
   * @returns {Promise<string>} - Absolute path of saved screenshot
   */
  static async capture(driver, name, isFailure = false) {
    try {
      const baseDir = path.resolve(process.env.REPORT_DIR || './reports');
      const subDir  = isFailure ? 'failures' : 'screenshots';
      const outDir  = path.join(baseDir, subDir);
      if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const sanitized = name.replace(/[^a-zA-Z0-9_-]/g, '_').substring(0, 80);
      const fileName  = `${sanitized}_${timestamp}.png`;
      const filePath  = path.join(outDir, fileName);

      const screenshot = await driver.takeScreenshot();
      fs.writeFileSync(filePath, Buffer.from(screenshot, 'base64'));
      logger.info(`Screenshot saved: ${filePath}`);
      return filePath;
    } catch (err) {
      logger.warn(`Screenshot capture failed: ${err.message}`);
      return '';
    }
  }

  /**
   * Capture a failure screenshot with device logs and widget tree.
   * @param {WebdriverIO.Browser} driver
   * @param {string} testName
   * @param {Error} error
   * @returns {Promise<{screenshotPath:string, logPath:string}>}
   */
  static async captureFailure(driver, testName, error) {
    const screenshotPath = await ScreenshotUtil.capture(driver, `FAIL_${testName}`, true);

    // ─── Device Logcat ───────────────────────────────────────
    let logPath = '';
    try {
      const baseDir = path.resolve(process.env.REPORT_DIR || './reports', 'failures');
      if (!fs.existsSync(baseDir)) fs.mkdirSync(baseDir, { recursive: true });

      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const sanitized = testName.replace(/[^a-zA-Z0-9_-]/g, '_').substring(0, 80);
      logPath = path.join(baseDir, `${sanitized}_${timestamp}.log`);

      let logContent = `=== FAILURE REPORT ===\n`;
      logContent += `Test: ${testName}\n`;
      logContent += `Time: ${new Date().toISOString()}\n`;
      logContent += `Error: ${error?.message || 'Unknown error'}\n`;
      logContent += `Stack:\n${error?.stack || 'N/A'}\n\n`;

      // Try to get page source / widget tree
      try {
        const pageSource = await driver.getPageSource();
        logContent += `=== WIDGET TREE (Page Source) ===\n${pageSource}\n`;
      } catch {
        logContent += `=== WIDGET TREE: unavailable ===\n`;
      }

      // Try to get device logs
      try {
        const logs = await driver.getLogs('logcat');
        const recentLogs = logs.slice(-100).map(l => `[${l.level}] ${l.message}`).join('\n');
        logContent += `\n=== DEVICE LOGCAT (last 100) ===\n${recentLogs}\n`;
      } catch {
        logContent += `\n=== DEVICE LOGCAT: unavailable ===\n`;
      }

      fs.writeFileSync(logPath, logContent, 'utf8');
      logger.info(`Failure log saved: ${logPath}`);
    } catch (logErr) {
      logger.warn(`Failure log capture failed: ${logErr.message}`);
    }

    return { screenshotPath, logPath };
  }
}

module.exports = ScreenshotUtil;
