'use strict';
const { remote } = require('webdriverio');
const appiumConfig = require('./appium.config');
const logger = require('../utils/logger');

let _driver = null;
let _driverMode = null; // 'flutter' | 'uiautomator2'

/**
 * DriverFactory – Creates and manages Appium WebdriverIO sessions.
 * Tries Flutter driver first; falls back to UiAutomator2 automatically.
 */
class DriverFactory {
  /**
   * @returns {Promise<WebdriverIO.Browser>}
   */
  static async createDriver() {
    if (_driver) {
      logger.warn('DriverFactory: Reusing existing driver session.');
      return _driver;
    }

    logger.info('DriverFactory: Attempting Flutter driver session...');

    try {
      _driver = await remote({
        hostname: appiumConfig.server.host,
        port: appiumConfig.server.port,
        path: appiumConfig.server.basePath,
        capabilities: appiumConfig.capabilities,
        connectionRetryCount: appiumConfig.server.connectionRetryCount,
        connectionRetryTimeout: appiumConfig.server.connectionRetryTimeout,
        logLevel: 'warn',
      });
      _driverMode = 'flutter';
      logger.info(`DriverFactory: Flutter driver session started [${_driver.sessionId}]`);
    } catch (flutterErr) {
      logger.warn(`DriverFactory: Flutter driver failed — ${flutterErr.message}`);
      logger.info('DriverFactory: Falling back to UiAutomator2...');

      try {
        _driver = await remote({
          hostname: appiumConfig.server.host,
          port: appiumConfig.server.port,
          path: appiumConfig.server.basePath,
          capabilities: appiumConfig.uiautomator2Capabilities,
          connectionRetryCount: appiumConfig.server.connectionRetryCount,
          connectionRetryTimeout: appiumConfig.server.connectionRetryTimeout,
          logLevel: 'warn',
        });
        _driverMode = 'uiautomator2';
        logger.info(`DriverFactory: UiAutomator2 fallback session started [${_driver.sessionId}]`);
      } catch (fallbackErr) {
        logger.error(`DriverFactory: Both driver modes failed — ${fallbackErr.message}`);
        throw fallbackErr;
      }
    }

    return _driver;
  }

  /** @returns {WebdriverIO.Browser|null} */
  static getDriver() {
    return _driver;
  }

  /** @returns {'flutter'|'uiautomator2'|null} */
  static getMode() {
    return _driverMode;
  }

  /** @returns {boolean} */
  static isFlutterMode() {
    return _driverMode === 'flutter';
  }

  /**
   * Terminates the current driver session gracefully.
   */
  static async destroyDriver() {
    if (_driver) {
      try {
        await _driver.deleteSession();
        logger.info('DriverFactory: Driver session terminated.');
      } catch (err) {
        logger.warn(`DriverFactory: Error while terminating session — ${err.message}`);
      } finally {
        _driver = null;
        _driverMode = null;
      }
    }
  }

  /**
   * Restarts the driver session (useful for test isolation).
   */
  static async restartDriver() {
    await DriverFactory.destroyDriver();
    return DriverFactory.createDriver();
  }
}

module.exports = DriverFactory;
