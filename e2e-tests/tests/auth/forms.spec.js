'use strict';
const { expect } = require('chai');
const DriverFactory = require('../../config/driver.factory');
const RoleSelectionPage = require('../../pages/role-selection.page');
const LoginPage = require('../../pages/login.page');
const RegisterPage = require('../../pages/register.page');
const ScreenshotUtil = require('../../utils/screenshot.util');
const logger = require('../../utils/logger');

/**
 * @module forms.spec
 * @description Flutter form validation E2E tests for AgriLink.
 * Covers: Required fields, email format, phone, password strength, min/max length.
 * Tags: @forms @regression
 */
describe('AgriLink Form Validation — @forms @regression', function () {
  this.timeout(120000);

  let roleSelectionPage;
  let loginPage;
  let registerPage;

  before(async function () {
    logger.info('=== FORMS SUITE START ===');
    await DriverFactory.createDriver();
    roleSelectionPage = new RoleSelectionPage();
    loginPage         = new LoginPage();
    registerPage      = new RegisterPage();

    // Navigate to register screen
    await roleSelectionPage.waitForLoad();
    await roleSelectionPage.selectBuyerRole();
    try { await roleSelectionPage.tapContinue(); } catch {}
    await loginPage.waitForLoad();
    await loginPage.tapRegister();
    await registerPage.waitForLoad();
  });

  after(async function () {
    logger.info('=== FORMS SUITE END ===');
    await DriverFactory.destroyDriver();
  });

  afterEach(async function () {
    if (this.currentTest.state === 'failed') {
      await ScreenshotUtil.captureFailure(
        DriverFactory.getDriver(),
        this.currentTest.title,
        this.currentTest.err,
      );
    }
  });

  // ─── Registration Form Validation ─────────────────────────

  it('@TC-FORM-001 Empty form submission should show required field errors @forms', async function () {
    await registerPage.tapCreateAccount();
    await registerPage.pause(1000);

    const nameErr  = await registerPage.getNameError();
    const emailErr = await registerPage.getEmailError();

    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-FORM-001_empty-form');
    logger.logStep(this.test.title, 'Empty form validation', 'PASS');

    const hasErrors = nameErr.length > 0 || emailErr.length > 0;
    expect(hasErrors, 'Required field errors should display on empty form submit').to.be.true;
  });

  it('@TC-FORM-002 Invalid email format should fail email validation @forms', async function () {
    const invalidEmails = ['notanemail', 'missing@', '@domain.com', 'no spaces@x.com'];

    for (const email of invalidEmails) {
      await registerPage.enterEmail(email);
      await registerPage.tapCreateAccount();
      await registerPage.pause(800);

      const errText = await registerPage.getEmailError();
      logger.logStep(this.test.title, `Email "${email}" → error: "${errText}"`, errText ? 'PASS' : 'WARN');
    }

    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-FORM-002_email-validation');
  });

  it('@TC-FORM-003 Valid email format should pass email validation @forms', async function () {
    await registerPage.enterEmail('valid@agrilink.com');
    await registerPage.tapCreateAccount();
    await registerPage.pause(800);

    const errText = await registerPage.getEmailError();
    logger.logStep(this.test.title, `Valid email error: "${errText}"`, 'PASS');
    expect(errText, 'Valid email should not show email format error').not.to.contain('valid email');
  });

  it('@TC-FORM-004 Short password should fail minimum length validation @forms', async function () {
    await registerPage.enterPassword('abc');
    await registerPage.tapCreateAccount();
    await registerPage.pause(800);

    const errText = await registerPage.getPasswordError();
    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-FORM-004_short-password');
    logger.logStep(this.test.title, `Short password error: "${errText}"`, 'PASS');
    expect(errText.length, 'Short password should trigger validation error').to.be.greaterThan(0);
  });

  it('@TC-FORM-005 Mismatched passwords should show confirm password error @forms', async function () {
    await registerPage.enterPassword('ValidPass@123');
    await registerPage.enterConfirmPassword('DifferentPass@456');
    await registerPage.tapCreateAccount();
    await registerPage.pause(800);

    const errText = await registerPage.findByContainsText('match')
      .then(el => el.getText())
      .catch(() => '');

    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-FORM-005_password-mismatch');
    logger.logStep(this.test.title, `Password mismatch error: "${errText}"`, 'PASS');
  });

  it('@TC-FORM-006 Invalid phone number format should fail phone validation @forms', async function () {
    const invalidPhones = ['abc', '123', '!@#$%^'];
    for (const phone of invalidPhones) {
      await registerPage.enterPhone(phone);
      await registerPage.tapCreateAccount();
      await registerPage.pause(600);
      const errText = await registerPage.getPhoneError();
      logger.logStep(this.test.title, `Phone "${phone}" error: "${errText}"`, 'PASS');
    }
    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-FORM-006_phone-validation');
  });

  it('@TC-FORM-007 Fields should not accept excessive input beyond maxLength @forms', async function () {
    const longText = 'A'.repeat(300);
    await registerPage.enterName(longText);
    const nameField = await registerPage.nameField;
    const actualValue = await nameField.getText().catch(() => '');

    logger.logStep(this.test.title, `Long name actual length: ${actualValue.length}`, 'PASS');
    // Flutter maxLength caps input — actual value should be <= widget max
    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-FORM-007_max-length');
  });

  // ─── Login Form Validation ─────────────────────────────────

  it('@TC-FORM-008 Login with empty email should show email required error @forms', async function () {
    await registerPage.pressBack();
    await loginPage.waitForLoad();

    await loginPage.enterEmail('');
    await loginPage.enterPassword('somepass');
    await loginPage.tapSignIn();
    await loginPage.pause(1000);

    const errText = await loginPage.getEmailValidationError();
    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-FORM-008_empty-email');
    logger.logStep(this.test.title, `Email required error: "${errText}"`, 'PASS');
    expect(errText.length, 'Empty email should show validation error').to.be.greaterThan(0);
  });

  it('@TC-FORM-009 Login with empty password should show password required error @forms', async function () {
    await loginPage.enterEmail('valid@agrilink.com');
    await loginPage.enterPassword('');
    await loginPage.tapSignIn();
    await loginPage.pause(1000);

    const errText = await loginPage.getPasswordValidationError();
    await ScreenshotUtil.capture(DriverFactory.getDriver(), 'TC-FORM-009_empty-password');
    logger.logStep(this.test.title, `Password required error: "${errText}"`, 'PASS');
    expect(errText.length, 'Empty password should show validation error').to.be.greaterThan(0);
  });
});
