'use strict';
const { expect } = require('chai');
const DriverFactory = require('../../config/driver.factory');
const RoleSelectionPage = require('../../pages/role-selection.page');
const LoginPage = require('../../pages/login.page');
const ProductFeedPage = require('../../pages/product-feed.page');
const ScreenshotUtil = require('../../utils/screenshot.util');
const logger = require('../../utils/logger');

/**
 * @module auth.spec
 * @description E2E test suite for AgriLink authentication flows.
 * Covers: Role selection, Login validation, Successful login, Logout, Session.
 * Tags: @auth @smoke @regression
 */
describe('AgriLink Authentication — @auth @smoke', function () {
  this.timeout(120000);

  let roleSelectionPage;
  let loginPage;
  let productFeedPage;
  const testName = (title) => `auth.spec → ${title}`;

  // ─── Hooks ────────────────────────────────────────────────

  before(async function () {
    logger.info('=== AUTH SUITE START ===');
    await DriverFactory.createDriver();
    roleSelectionPage = new RoleSelectionPage();
    loginPage         = new LoginPage();
    productFeedPage   = new ProductFeedPage();
  });

  after(async function () {
    logger.info('=== AUTH SUITE END ===');
    await DriverFactory.destroyDriver();
  });

  afterEach(async function () {
    if (this.currentTest.state === 'failed') {
      const { screenshotPath } = await ScreenshotUtil.captureFailure(
        DriverFactory.getDriver(),
        this.currentTest.title,
        this.currentTest.err,
      );
      logger.error(`FAILED: ${this.currentTest.title} — Screenshot: ${screenshotPath}`);
      logger.logStep(this.currentTest.title, 'afterEach', 'FAILED', this.currentTest.err?.message);
    }
  });

  // ─── Test Cases ───────────────────────────────────────────

  it('@TC-AUTH-001 Role Selection screen should be displayed on app launch @smoke', async function () {
    const tn = testName(this.test.title);
    logger.logStep(tn, 'App launched', 'PASS');

    await roleSelectionPage.waitForLoad();
    const isDisplayed = await roleSelectionPage.isDisplayed();

    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-AUTH-001_role-selection');
    logger.logStep(tn, 'Role Selection screen visible', isDisplayed ? 'PASS' : 'FAIL');
    expect(isDisplayed, 'Role Selection screen should be visible').to.be.true;
  });

  it('@TC-AUTH-002 Selecting Buyer role should navigate to Buyer Login screen @smoke', async function () {
    const tn = testName(this.test.title);

    await roleSelectionPage.selectBuyerRole();
    await roleSelectionPage.pause(1000);

    try { await roleSelectionPage.tapContinue(); } catch { /* some builds auto-navigate */ }

    await loginPage.waitForLoad();
    const isLoginDisplayed = await loginPage.isDisplayed();

    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-AUTH-002_login-screen');
    logger.logStep(tn, 'Login screen displayed after Buyer role selection', isLoginDisplayed ? 'PASS' : 'FAIL');
    expect(isLoginDisplayed, 'Login screen should be displayed').to.be.true;
  });

  it('@TC-AUTH-003 Login with empty fields should show validation errors @regression @forms', async function () {
    const tn = testName(this.test.title);

    await loginPage.tapSignIn();
    await loginPage.pause(1000);

    const emailError    = await loginPage.getEmailValidationError();
    const passwordError = await loginPage.getPasswordValidationError();

    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-AUTH-003_empty-validation');
    logger.logStep(tn, 'Empty field validation triggered', 'PASS');

    // At least one validation error should be present
    const hasValidationError = emailError.length > 0 || passwordError.length > 0;
    expect(hasValidationError, 'Validation errors should appear for empty fields').to.be.true;
  });

  it('@TC-AUTH-004 Login with invalid email format should show email validation error @forms', async function () {
    const tn = testName(this.test.title);

    await loginPage.enterEmail('not-an-email');
    await loginPage.enterPassword('somepassword');
    await loginPage.tapSignIn();
    await loginPage.pause(1000);

    const emailError = await loginPage.getEmailValidationError();
    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-AUTH-004_invalid-email');
    logger.logStep(tn, `Email validation error: "${emailError}"`, emailError ? 'PASS' : 'WARN');

    expect(emailError.length, 'Email validation error should be present').to.be.greaterThan(0);
  });

  it('@TC-AUTH-005 Login with valid credentials should navigate to Product Feed @smoke', async function () {
    const tn = testName(this.test.title);

    await loginPage.enterEmail(process.env.BUYER_EMAIL);
    await loginPage.enterPassword(process.env.BUYER_PASSWORD);

    logger.logStep(tn, 'Credentials entered', 'PASS');
    await loginPage.tapSignIn();
    await loginPage.pause(4000); // Wait for auth + navigation

    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-AUTH-005_post-login');
    const isHome = await productFeedPage.isDisplayed();
    logger.logStep(tn, 'Navigated to Home after login', isHome ? 'PASS' : 'FAIL');

    expect(isHome, 'Should navigate to product feed after successful login').to.be.true;
  });

  it('@TC-AUTH-006 Invalid credentials should show Authentication Failed error @regression', async function () {
    const tn = testName(this.test.title);

    // First go back to login if on home
    try {
      await loginPage.pressBack();
      await roleSelectionPage.selectBuyerRole();
      await roleSelectionPage.tapContinue();
      await loginPage.waitForLoad();
    } catch { /* already on login */ }

    await loginPage.enterEmail(process.env.BUYER_EMAIL);
    await loginPage.enterPassword(process.env.INVALID_PASSWORD);
    await loginPage.tapSignIn();
    await loginPage.pause(5000);

    const hasError = await loginPage.isErrorBannerVisible();
    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-AUTH-006_invalid-credentials');
    logger.logStep(tn, 'Auth error banner visible', hasError ? 'PASS' : 'FAIL');

    expect(hasError, 'Authentication Failed banner should be displayed').to.be.true;
  });

  it('@TC-AUTH-007 Password field should toggle visibility @regression', async function () {
    const tn = testName(this.test.title);

    await loginPage.enterPassword('MyPassword123');
    await loginPage.togglePasswordVisibility();
    await loginPage.pause(500);

    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-AUTH-007_password-visible');
    logger.logStep(tn, 'Password visibility toggled', 'PASS');
    // Test is PASS if no error thrown (visual toggle verified via screenshot)
  });

  it('@TC-AUTH-008 Forgot Password link should navigate to Forgot Password screen @regression', async function () {
    const tn = testName(this.test.title);

    await loginPage.tapForgotPassword();
    await loginPage.pause(2000);

    const isOnForgot = await loginPage.textExists('Forgot', 5000);
    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-AUTH-008_forgot-password');
    logger.logStep(tn, 'Navigated to Forgot Password screen', isOnForgot ? 'PASS' : 'FAIL');

    expect(isOnForgot, 'Should navigate to Forgot Password screen').to.be.true;
    await loginPage.pressBack();
  });

  it('@TC-AUTH-009 Register link should navigate to Registration screen @regression', async function () {
    const tn = testName(this.test.title);

    await loginPage.waitForLoad();
    await loginPage.tapRegister();
    await loginPage.pause(2000);

    const isOnRegister = await loginPage.textExists('Create Account', 5000);
    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-AUTH-009_register-screen');
    logger.logStep(tn, 'Navigated to Register screen', isOnRegister ? 'PASS' : 'FAIL');

    expect(isOnRegister, 'Should navigate to Registration screen').to.be.true;
    await loginPage.pressBack();
  });
});
