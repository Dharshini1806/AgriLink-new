'use strict';
const { execSync } = require('child_process');
require('dotenv').config();

/**
 * Global Mocha Root Hooks
 * - Verifies Appium server is running before any test
 * - Adds global reporter for Excel on complete
 */

const axios = require('axios');
const MochaExcelPlugin = require('./reporters/mocha.reporter');
const logger = require('./utils/logger');

let excelPlugin;

exports.mochaHooks = {
  async beforeAll() {
    logger.info('🌾 AgriLink E2E Framework Starting...');
    logger.info(`   Node: ${process.version}`);
    logger.info(`   Device: ${process.env.DEVICE_NAME || 'emulator-5554'}`);
    logger.info(`   Platform: Android ${process.env.PLATFORM_VERSION || '13.0'}`);
    logger.info(`   Mode: ${process.env.NODE_ENV || 'test'}\n`);

    // Verify Appium server
    const host = process.env.APPIUM_HOST || 'localhost';
    const port = process.env.APPIUM_PORT || '4723';
    try {
      const res = await axios.get(`http://${host}:${port}/status`, { timeout: 5000 });
      logger.info(`✅ Appium server ready: ${JSON.stringify(res.data?.value?.build || {})}`);
    } catch {
      logger.error(`❌ Appium server not reachable at http://${host}:${port}/status`);
      logger.error('   → Start Appium: npm run appium:start');
      throw new Error('Appium server is not running. Start it with: npm run appium:start');
    }

    // Attach Excel plugin to Mocha runner
    excelPlugin = new MochaExcelPlugin();
    if (this._runnable && this._runnable.ctx && this._runnable.ctx.currentRunnable) {
      const runner = this._runnable.ctx.currentRunnable._currentRetry !== undefined
        ? this._runnable.ctx : null;
      if (runner) excelPlugin.attach(runner);
    }
  },

  async afterAll() {
    logger.info('\n🏁 AgriLink E2E Framework Complete.');
  },
};
