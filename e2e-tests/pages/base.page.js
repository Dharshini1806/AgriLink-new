'use strict';
const DriverFactory = require('../config/driver.factory');
const ScreenshotUtil = require('../utils/screenshot.util');
const GestureUtil = require('../utils/gesture.util');
const logger = require('../utils/logger');

/**
 * BasePage — Parent class for all Page Objects.
 *
 * Provides:
 * - Flutter finder APIs (byValueKey, byText, bySemanticsLabel, byType)
 * - UiAutomator2 element finders (fallback)
 * - Smart waits
 * - Screenshot helpers
 * - Gesture shortcuts
 */
class BasePage {
  constructor() {
    this.defaultTimeout = parseInt(process.env.EXPLICIT_TIMEOUT) || 30000;
    this.implicitTimeout = parseInt(process.env.IMPLICIT_TIMEOUT) || 8000;
  }

  /** @returns {WebdriverIO.Browser} */
  get driver() {
    return DriverFactory.getDriver();
  }

  /** @returns {boolean} */
  get isFlutter() {
    return DriverFactory.isFlutterMode();
  }

  // ──────────────────────────────────────────────────────────
  //  Flutter Finder APIs
  // ──────────────────────────────────────────────────────────

  /**
   * Find Flutter widget by ValueKey.
   * @param {string} key
   * @returns {Promise<WebdriverIO.Element>}
   */
  async findByValueKey(key) {
    logger.debug(`Flutter: findByValueKey("${key}")`);
    return this.driver.$(`~${key}`);  // Accessibility ID / ValueKey
  }

  /**
   * Find Flutter widget by text content.
   * @param {string} text
   * @returns {Promise<WebdriverIO.Element>}
   */
  async findByText(text) {
    logger.debug(`Flutter: findByText("${text}")`);
    if (this.isFlutter) {
      return this.driver.$(`flutter=text('${text}')`);
    }
    return this.driver.$(`//*[@text="${text}" or @content-desc="${text}"]`);
  }

  /**
   * Find Flutter widget by semantics label.
   * @param {string} label
   * @returns {Promise<WebdriverIO.Element>}
   */
  async findBySemanticsLabel(label) {
    logger.debug(`Flutter: findBySemanticsLabel("${label}")`);
    return this.driver.$(`~${label}`);
  }

  /**
   * Find Flutter widget by type (e.g., 'ElevatedButton', 'TextField').
   * @param {string} type
   * @returns {Promise<WebdriverIO.Element>}
   */
  async findByType(type) {
    logger.debug(`Flutter: findByType("${type}")`);
    if (this.isFlutter) {
      return this.driver.$(`flutter=type('${type}')`);
    }
    return this.driver.$(`android.widget.${type}`);
  }

  /**
   * Find all matching elements by text.
   */
  async findAllByText(text) {
    if (this.isFlutter) {
      return this.driver.$$(`flutter=text('${text}')`);
    }
    return this.driver.$$(`//*[@text="${text}"]`);
  }

  // ──────────────────────────────────────────────────────────
  //  UiAutomator2 / XPath Finders (Fallback)
  // ──────────────────────────────────────────────────────────

  async findByXPath(xpath) {
    return this.driver.$(xpath);
  }

  async findByResourceId(resourceId) {
    return this.driver.$(`id:${resourceId}`);
  }

  async findByClassName(className) {
    return this.driver.$(`android.widget.${className}`);
  }

  async findByContainsText(text) {
    return this.driver.$(`//*[contains(@text, "${text}") or contains(@content-desc, "${text}")]`);
  }

  // ──────────────────────────────────────────────────────────
  //  Smart Waits
  // ──────────────────────────────────────────────────────────

  /**
   * Wait for element to be displayed.
   */
  async waitForVisible(element, timeout = this.defaultTimeout) {
    await element.waitForDisplayed({ timeout, timeoutMsg: `Element not visible within ${timeout}ms` });
    return element;
  }

  /**
   * Wait for element to be clickable.
   */
  async waitForClickable(element, timeout = this.defaultTimeout) {
    await element.waitForEnabled({ timeout, timeoutMsg: `Element not clickable within ${timeout}ms` });
    return element;
  }

  /**
   * Wait until a text is present on screen.
   */
  async waitForText(text, timeout = this.defaultTimeout) {
    const el = await this.findByText(text);
    await this.waitForVisible(el, timeout);
    return el;
  }

  /**
   * Wait for element to disappear.
   */
  async waitForHidden(element, timeout = this.defaultTimeout) {
    await element.waitForDisplayed({ timeout, reverse: true });
  }

  /**
   * Wait for a specific duration.
   */
  async pause(ms = 1000) {
    return GestureUtil.pause(ms);
  }

  // ──────────────────────────────────────────────────────────
  //  Form Helpers
  // ──────────────────────────────────────────────────────────

  /**
   * Clear a field and type text.
   */
  async clearAndType(element, text) {
    logger.debug(`Form: clearAndType("${text}")`);
    await element.clearValue();
    await element.setValue(text);
  }

  /**
   * Get text content of element.
   */
  async getText(element) {
    return element.getText();
  }

  /**
   * Get attribute value.
   */
  async getAttribute(element, attr) {
    return element.getAttribute(attr);
  }

  /**
   * Check if element exists (non-throwing).
   */
  async exists(locator, timeout = 3000) {
    try {
      const el = typeof locator === 'string' ? await this.driver.$(locator) : locator;
      await el.waitForExist({ timeout });
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Check if text exists on screen.
   */
  async textExists(text, timeout = 5000) {
    return this.exists(
      this.isFlutter
        ? `flutter=text('${text}')`
        : `//*[@text="${text}" or contains(@content-desc, "${text}")]`,
      timeout,
    );
  }

  // ──────────────────────────────────────────────────────────
  //  Screenshot Shortcuts
  // ──────────────────────────────────────────────────────────

  async screenshot(name) {
    return ScreenshotUtil.capture(this.driver, name, false);
  }

  async screenshotOnFailure(testName, error) {
    return ScreenshotUtil.captureFailure(this.driver, testName, error);
  }

  // ──────────────────────────────────────────────────────────
  //  Gesture Shortcuts
  // ──────────────────────────────────────────────────────────

  async scrollDown(amount = 800) {
    return GestureUtil.scrollDown(this.driver, amount);
  }

  async scrollUp(amount = 800) {
    return GestureUtil.scrollUp(this.driver, amount);
  }

  async swipeLeft() {
    return GestureUtil.swipeLeft(this.driver);
  }

  async swipeRight() {
    return GestureUtil.swipeRight(this.driver);
  }

  async pressBack() {
    return GestureUtil.pressBack(this.driver);
  }

  async longPress(element, duration) {
    return GestureUtil.longPress(this.driver, element, duration);
  }

  async scrollToText(text) {
    return GestureUtil.scrollToText(this.driver, text);
  }

  // ──────────────────────────────────────────────────────────
  //  Navigation Helpers
  // ──────────────────────────────────────────────────────────

  async getCurrentActivity() {
    try {
      return await this.driver.getCurrentActivity();
    } catch {
      return 'unknown';
    }
  }

  async getPageSource() {
    return this.driver.getPageSource();
  }
}

module.exports = BasePage;
