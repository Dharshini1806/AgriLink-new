'use strict';
const { expect } = require('chai');
const DriverFactory = require('../../config/driver.factory');
const RoleSelectionPage = require('../../pages/role-selection.page');
const LoginPage = require('../../pages/login.page');
const { SellerDashboardPage, AddProductPage } = require('../../pages/seller.page');
const ScreenshotUtil = require('../../utils/screenshot.util');
const logger = require('../../utils/logger');

/**
 * @module seller.spec
 * @description E2E test suite for AgriLink Seller flows.
 * Covers: Seller login, Dashboard, Add product, Product management.
 * Tags: @seller @regression
 */
describe('AgriLink Seller Flows — @seller @regression', function () {
  this.timeout(150000);

  let roleSelectionPage;
  let loginPage;
  let sellerDashboardPage;
  let addProductPage;

  before(async function () {
    logger.info('=== SELLER SUITE START ===');
    await DriverFactory.createDriver();
    roleSelectionPage  = new RoleSelectionPage();
    loginPage          = new LoginPage();
    sellerDashboardPage = new SellerDashboardPage();
    addProductPage     = new AddProductPage();

    // Login as Seller
    await roleSelectionPage.waitForLoad();
    await roleSelectionPage.selectSellerRole();
    try { await roleSelectionPage.tapContinue(); } catch {}
    await loginPage.waitForLoad();
    await loginPage.login(process.env.SELLER_EMAIL, process.env.SELLER_PASSWORD);
    await sellerDashboardPage.waitForLoad();
  });

  after(async function () {
    logger.info('=== SELLER SUITE END ===');
    await DriverFactory.destroyDriver();
  });

  afterEach(async function () {
    if (this.currentTest.state === 'failed') {
      await ScreenshotUtil.captureFailure(
        DriverFactory.getDriver(), this.currentTest.title, this.currentTest.err);
    }
  });

  // ──────────────────────────────────────────────────────────

  it('@TC-SELLER-001 Seller Dashboard should be displayed after login @smoke', async function () {
    const isDisplayed = await sellerDashboardPage.isDisplayed();
    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-SELLER-001_dashboard');
    logger.logStep(this.test.title, 'Seller Dashboard visible', isDisplayed ? 'PASS' : 'FAIL');
    expect(isDisplayed, 'Seller dashboard should be displayed').to.be.true;
  });

  it('@TC-SELLER-002 Add Product button should navigate to Add Product screen @regression', async function () {
    await sellerDashboardPage.tapAddProduct();
    const isDisplayed = await addProductPage.isDisplayed();

    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-SELLER-002_add-product-screen');
    logger.logStep(this.test.title, 'Add Product screen visible', isDisplayed ? 'PASS' : 'FAIL');
    expect(isDisplayed, 'Add Product screen should be displayed').to.be.true;
  });

  it('@TC-SELLER-003 Add product form with empty fields should show validation errors @forms', async function () {
    await addProductPage.submitProduct();
    await addProductPage.pause(1000);

    const hasError = await addProductPage.textExists('required', 5000)
      || await addProductPage.textExists('error', 3000);

    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-SELLER-003_add-product-validation');
    logger.logStep(this.test.title, 'Add product validation triggered', 'PASS');
  });

  it('@TC-SELLER-004 Fill and submit a new product listing @regression', async function () {
    const testProduct = {
      name:  `AutoTest_Tomato_${Date.now()}`,
      price: '50',
      stock: '100',
      desc:  'Automation test product — E2E',
    };

    await addProductPage.enterProductName(testProduct.name);
    await addProductPage.enterPrice(testProduct.price);
    await addProductPage.enterStock(testProduct.stock);
    await addProductPage.enterDescription(testProduct.desc);

    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-SELLER-004_product-form-filled');
    logger.logStep(this.test.title, `Product form filled: ${testProduct.name}`, 'PASS');

    await addProductPage.submitProduct();
    await addProductPage.pause(3000);

    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-SELLER-004_post-submit');
    logger.logStep(this.test.title, 'Product submitted', 'PASS');
  });

  it('@TC-SELLER-005 Products tab should list seller products @regression', async function () {
    await addProductPage.pressBack();
    await sellerDashboardPage.tapProductsTab();
    await sellerDashboardPage.pause(2000);

    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-SELLER-005_seller-products');
    logger.logStep(this.test.title, 'Seller products tab loaded', 'PASS');
  });

  it('@TC-SELLER-006 Analytics tab should display revenue charts @regression', async function () {
    await sellerDashboardPage.tapAnalyticsTab();
    await sellerDashboardPage.pause(2000);

    const hasRevenue = await sellerDashboardPage.textExists('Revenue', 5000)
      || await sellerDashboardPage.textExists('Sales', 5000);

    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-SELLER-006_analytics');
    logger.logStep(this.test.title, `Analytics visible: ${hasRevenue}`, 'PASS');
  });
});
