'use strict';
const logger = require('./logger');

/**
 * GestureUtil — Reusable gesture helpers for Flutter/Android Appium automation.
 * Supports: tap, doubleTap, longPress, scroll, swipe, drag, pinch, zoom.
 */
class GestureUtil {
  /**
   * Simple tap on an element.
   * @param {WebdriverIO.Element} element
   */
  static async tap(element) {
    logger.debug('Gesture: tap');
    await element.click();
  }

  /**
   * Tap on screen coordinates.
   * @param {WebdriverIO.Browser} driver
   * @param {number} x
   * @param {number} y
   */
  static async tapCoordinates(driver, x, y) {
    logger.debug(`Gesture: tapCoordinates(${x}, ${y})`);
    await driver.touchAction({ action: 'tap', x, y });
  }

  /**
   * Double tap on an element.
   * @param {WebdriverIO.Browser} driver
   * @param {WebdriverIO.Element} element
   */
  static async doubleTap(driver, element) {
    logger.debug('Gesture: doubleTap');
    const { x, y, width, height } = await element.getRect();
    const cx = Math.round(x + width / 2);
    const cy = Math.round(y + height / 2);
    await driver.touchAction([
      { action: 'tap', x: cx, y: cy },
      { action: 'tap', x: cx, y: cy },
    ]);
  }

  /**
   * Long press on an element.
   * @param {WebdriverIO.Browser} driver
   * @param {WebdriverIO.Element} element
   * @param {number} duration - Duration in ms (default 1500)
   */
  static async longPress(driver, element, duration = 1500) {
    logger.debug(`Gesture: longPress (${duration}ms)`);
    const { x, y, width, height } = await element.getRect();
    const cx = Math.round(x + width / 2);
    const cy = Math.round(y + height / 2);
    await driver.touchAction([
      { action: 'press', x: cx, y: cy },
      { action: 'wait', ms: duration },
      { action: 'release' },
    ]);
  }

  /**
   * Scroll down on the screen.
   * @param {WebdriverIO.Browser} driver
   * @param {number} scrollAmount - Pixels to scroll (default 800)
   */
  static async scrollDown(driver, scrollAmount = 800) {
    logger.debug(`Gesture: scrollDown (${scrollAmount}px)`);
    const { width, height } = await driver.getWindowSize();
    const startX = Math.round(width / 2);
    const startY = Math.round(height * 0.7);
    const endY   = Math.round(startY - scrollAmount);
    await driver.touchAction([
      { action: 'press', x: startX, y: startY },
      { action: 'wait', ms: 600 },
      { action: 'moveTo', x: startX, y: endY },
      { action: 'release' },
    ]);
  }

  /**
   * Scroll up on the screen.
   */
  static async scrollUp(driver, scrollAmount = 800) {
    logger.debug(`Gesture: scrollUp (${scrollAmount}px)`);
    const { width, height } = await driver.getWindowSize();
    const startX = Math.round(width / 2);
    const startY = Math.round(height * 0.3);
    const endY   = Math.round(startY + scrollAmount);
    await driver.touchAction([
      { action: 'press', x: startX, y: startY },
      { action: 'wait', ms: 600 },
      { action: 'moveTo', x: startX, y: endY },
      { action: 'release' },
    ]);
  }

  /**
   * Swipe left (e.g., next page in carousel).
   */
  static async swipeLeft(driver) {
    logger.debug('Gesture: swipeLeft');
    const { width, height } = await driver.getWindowSize();
    await driver.touchAction([
      { action: 'press', x: Math.round(width * 0.8), y: Math.round(height / 2) },
      { action: 'wait', ms: 600 },
      { action: 'moveTo', x: Math.round(width * 0.2), y: Math.round(height / 2) },
      { action: 'release' },
    ]);
  }

  /**
   * Swipe right.
   */
  static async swipeRight(driver) {
    logger.debug('Gesture: swipeRight');
    const { width, height } = await driver.getWindowSize();
    await driver.touchAction([
      { action: 'press', x: Math.round(width * 0.2), y: Math.round(height / 2) },
      { action: 'wait', ms: 600 },
      { action: 'moveTo', x: Math.round(width * 0.8), y: Math.round(height / 2) },
      { action: 'release' },
    ]);
  }

  /**
   * Drag from one element to another.
   */
  static async dragAndDrop(driver, sourceElem, targetElem) {
    logger.debug('Gesture: dragAndDrop');
    const src = await sourceElem.getRect();
    const tgt = await targetElem.getRect();
    const srcCx = Math.round(src.x + src.width / 2);
    const srcCy = Math.round(src.y + src.height / 2);
    const tgtCx = Math.round(tgt.x + tgt.width / 2);
    const tgtCy = Math.round(tgt.y + tgt.height / 2);
    await driver.touchAction([
      { action: 'press', x: srcCx, y: srcCy },
      { action: 'wait', ms: 1000 },
      { action: 'moveTo', x: tgtCx, y: tgtCy },
      { action: 'release' },
    ]);
  }

  /**
   * Pinch to zoom out.
   */
  static async pinchZoomOut(driver) {
    logger.debug('Gesture: pinchZoomOut');
    const { width, height } = await driver.getWindowSize();
    const cx = Math.round(width / 2);
    const cy = Math.round(height / 2);
    await driver.multiAction([
      driver.touchAction([
        { action: 'press', x: cx - 100, y: cy },
        { action: 'wait', ms: 500 },
        { action: 'moveTo', x: cx - 20, y: cy },
        { action: 'release' },
      ]),
      driver.touchAction([
        { action: 'press', x: cx + 100, y: cy },
        { action: 'wait', ms: 500 },
        { action: 'moveTo', x: cx + 20, y: cy },
        { action: 'release' },
      ]),
    ]);
  }

  /**
   * Zoom in.
   */
  static async zoomIn(driver) {
    logger.debug('Gesture: zoomIn');
    const { width, height } = await driver.getWindowSize();
    const cx = Math.round(width / 2);
    const cy = Math.round(height / 2);
    await driver.multiAction([
      driver.touchAction([
        { action: 'press', x: cx - 20, y: cy },
        { action: 'wait', ms: 500 },
        { action: 'moveTo', x: cx - 150, y: cy },
        { action: 'release' },
      ]),
      driver.touchAction([
        { action: 'press', x: cx + 20, y: cy },
        { action: 'wait', ms: 500 },
        { action: 'moveTo', x: cx + 150, y: cy },
        { action: 'release' },
      ]),
    ]);
  }

  /**
   * Scroll until a text is visible (UiAutomator2 mode).
   */
  static async scrollToText(driver, text) {
    logger.debug(`Gesture: scrollToText("${text}")`);
    try {
      await driver.$(`android=new UiScrollable(new UiSelector().scrollable(true)).scrollIntoView(new UiSelector().text("${text}"))`);
    } catch {
      // Fallback: manual scrolls
      for (let i = 0; i < 5; i++) {
        await GestureUtil.scrollDown(driver, 400);
        try {
          const el = await driver.$(`//*[@text="${text}"]`);
          if (await el.isDisplayed()) return;
        } catch { /* keep scrolling */ }
      }
    }
  }

  /**
   * Wait for ms.
   */
  static async pause(ms = 1000) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Press Android back button.
   */
  static async pressBack(driver) {
    logger.debug('Gesture: pressBack');
    await driver.pressKeyCode(4);
  }

  /**
   * Press Android home button.
   */
  static async pressHome(driver) {
    logger.debug('Gesture: pressHome');
    await driver.pressKeyCode(3);
  }
}

module.exports = GestureUtil;
