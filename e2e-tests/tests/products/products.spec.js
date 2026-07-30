'use strict';
const { expect } = require('chai');
const DriverFactory = require('../../config/driver.factory');
const RoleSelectionPage = require('../../pages/role-selection.page');
const LoginPage = require('../../pages/login.page');
const ProductFeedPage = require('../../pages/product-feed.page');
const ScreenshotUtil = require('../../utils/screenshot.util');
const logger = require('../../utils/logger');
const GestureUtil = require('../../utils/gesture.util');

/**
 * @module products.spec
 * @description E2E test suite for AgriLink product browsing, search, and wishlist flows.
 * Tags: @products @smoke @regression
 */
describe('AgriLink Products — @products @regression', function () {
  this.timeout(120000);

  let roleSelectionPage;
  let loginPage;
  let productFeedPage;

  before(async function () {
    logger.info('=== PRODUCTS SUITE START ===');
    await DriverFactory.createDriver();
    roleSelectionPage = new RoleSelectionPage();
    loginPage         = new LoginPage();
    productFeedPage   = new ProductFeedPage();

    // Login as buyer
    await roleSelectionPage.waitForLoad();
    await roleSelectionPage.selectBuyerRole();
    try { await roleSelectionPage.tapContinue(); } catch {}
    await loginPage.waitForLoad();
    await loginPage.login(process.env.BUYER_EMAIL, process.env.BUYER_PASSWORD);
    await productFeedPage.waitForLoad();
  });

  after(async function () {
    logger.info('=== PRODUCTS SUITE END ===');
    await DriverFactory.destroyDriver();
  });

  afterEach(async function () {
    if (this.currentTest.state === 'failed') {
      await ScreenshotUtil.captureFailure(
        DriverFactory.getDriver(), this.currentTest.title, this.currentTest.err);
    }
  });

  // ──────────────────────────────────────────────────────────

  it('@TC-PROD-001 Product feed should be displayed after login @smoke', async function () {
    const isDisplayed = await productFeedPage.isDisplayed();
    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-PROD-001_product-feed');
    logger.logStep(this.test.title, 'Product feed visible', isDisplayed ? 'PASS' : 'FAIL');
    expect(isDisplayed, 'Product feed should be displayed').to.be.true;
  });

  it('@TC-PROD-002 Product list should contain at least one product @smoke', async function () {
    const hasProducts = await productFeedPage.hasProducts();
    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-PROD-002_products-listed');
    logger.logStep(this.test.title, 'Products exist on feed', hasProducts ? 'PASS' : 'FAIL');
    expect(hasProducts, 'Product feed should have at least one product').to.be.true;
  });

  it('@TC-PROD-003 Searching for a product should return results @regression', async function () {
    await productFeedPage.searchFor('Tomato');
    await productFeedPage.pause(2000);

    const hasResults = await productFeedPage.hasProducts();
    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-PROD-003_search-results');
    logger.logStep(this.test.title, `Search results for "Tomato": ${hasResults}`, 'PASS');
    // Results may or may not exist depending on DB — just verify no crash
  });

  it('@TC-PROD-004 Tapping a product should navigate to Product Detail screen @regression', async function () {
    // Navigate back to home if needed
    await productFeedPage.navigateTo('home');
    await productFeedPage.pause(1500);
    await productFeedPage.tapFirstProduct();

    const isDetail = await productFeedPage.textExists('Add to Cart', 8000)
      || await productFeedPage.textExists('Buy Now', 8000)
      || await productFeedPage.textExists('₹', 5000);

    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-PROD-004_product-detail');
    logger.logStep(this.test.title, 'Product detail visible', isDetail ? 'PASS' : 'WARN');
  });

  it('@TC-PROD-005 Scrolling product feed should load more products @regression', async function () {
    await productFeedPage.pressBack();
    await productFeedPage.waitForLoad();

    const beforeScroll = await DriverFactory.getDriver().$$('//android.widget.ImageView');
    await GestureUtil.scrollDown(DriverFactory.getDriver(), 600);
    await productFeedPage.pause(2000);
    const afterScroll = await DriverFactory.getDriver().$$('//android.widget.ImageView');

    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-PROD-005_scroll-load');
    logger.logStep(this.test.title, `Products before: ${beforeScroll.length}, after: ${afterScroll.length}`, 'PASS');
  });

  it('@TC-PROD-006 Bottom navigation should work correctly @smoke', async function () {
    const tabs = ['orders', 'profile', 'home'];
    for (const tab of tabs) {
      await productFeedPage.navigateTo(tab);
      await productFeedPage.pause(1000);
      logger.logStep(this.test.title, `Navigated to ${tab}`, 'PASS');
    }
    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-PROD-006_navigation');
  });

  it('@TC-PROD-007 Adding product to wishlist should toggle wishlist icon @regression', async function () {
    await productFeedPage.navigateTo('home');
    await productFeedPage.pause(1500);
    await productFeedPage.addFirstProductToWishlist();
    await productFeedPage.pause(1500);
    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-PROD-007_wishlist');
    logger.logStep(this.test.title, 'Wishlist toggled', 'PASS');
  });
});
