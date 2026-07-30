'use strict';
require('dotenv').config();

/**
 * Appium 2.x Capabilities Configuration for AgriLink Flutter Android APK
 * Supports: Real Devices (Android 10–15+) and Emulators
 */
const appiumConfig = {
  server: {
    host: process.env.APPIUM_HOST || 'localhost',
    port: parseInt(process.env.APPIUM_PORT) || 4723,
    basePath: process.env.APPIUM_BASE_PATH || '/',
    connectionRetryCount: 3,
    connectionRetryTimeout: 90000,
  },

  capabilities: {
    // ─── Core Appium Caps ──────────────────────────────────
    platformName: 'Android',
    'appium:automationName': 'Flutter',              // Primary: Flutter driver
    'appium:deviceName': process.env.DEVICE_NAME || 'emulator-5554',
    'appium:platformVersion': process.env.PLATFORM_VERSION || '13.0',
    'appium:app': process.env.APK_PATH || './app/app-release.apk',
    'appium:appPackage': process.env.APP_PACKAGE || 'com.agrilink.app',
    'appium:appActivity': process.env.APP_ACTIVITY || 'com.agrilink.app.MainActivity',
    'appium:autoGrantPermissions': true,
    'appium:autoAcceptAlerts': true,
    'appium:noReset': false,
    'appium:fullReset': false,

    // ─── Install Config ────────────────────────────────────
    'appium:androidInstallTimeout': parseInt(process.env.INSTALL_TIMEOUT) || 120000,
    'appium:uiautomator2ServerInstallTimeout': 60000,
    'appium:uiautomator2ServerLaunchTimeout': 60000,

    // ─── Flutter-specific ──────────────────────────────────
    'appium:retryBackoffTime': 500,
    'appium:maxRetryCount': 5,
    'appium:waitForLaunch': true,

    // ─── Network ──────────────────────────────────────────
    'appium:newCommandTimeout': parseInt(process.env.COMMAND_TIMEOUT) || 300000,

    // ─── Logging ──────────────────────────────────────────
    'appium:printPageSourceOnFindFailure': true,
    'appium:showChromedriverLog': false,
  },

  /**
   * UiAutomator2 fallback capabilities (used when Flutter driver is unavailable)
   */
  uiautomator2Capabilities: {
    platformName: 'Android',
    'appium:automationName': 'UiAutomator2',
    'appium:deviceName': process.env.DEVICE_NAME || 'emulator-5554',
    'appium:platformVersion': process.env.PLATFORM_VERSION || '13.0',
    'appium:app': process.env.APK_PATH || './app/app-release.apk',
    'appium:appPackage': process.env.APP_PACKAGE || 'com.agrilink.app',
    'appium:appActivity': process.env.APP_ACTIVITY || 'com.agrilink.app.MainActivity',
    'appium:autoGrantPermissions': true,
    'appium:autoAcceptAlerts': true,
    'appium:newCommandTimeout': 300000,
    'appium:androidInstallTimeout': 120000,
    'appium:uiautomator2ServerInstallTimeout': 60000,
  },
};

module.exports = appiumConfig;
