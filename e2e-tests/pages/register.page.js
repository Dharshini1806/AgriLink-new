'use strict';
const BasePage = require('./base.page');
const logger = require('../utils/logger');

/**
 * RegisterPage — AgriLink registration screen.
 * Route: /register
 *
 * Fields (from register_screen.dart):
 *  - Full Name
 *  - Email
 *  - Phone
 *  - Password
 *  - Confirm Password
 *  - Capture Location button
 *  - Create Account button
 */
class RegisterPage extends BasePage {
  // ─── Locators ──────────────────────────────────────────────

  get nameField()    { return this.findByText('Full Name').catch(() => this.findByContainsText('Name')); }
  get emailField()   { return this.findByText('you@example.com').catch(() => this.findByContainsText('email')); }
  get phoneField()   { return this.findByContainsText('Phone'); }
  get passwordField()   { return this.driver.$('(//android.widget.EditText)[4]'); }
  get confirmField()    { return this.driver.$('(//android.widget.EditText)[5]'); }
  get locationBtn()     { return this.findByContainsText('Location').catch(() => this.findByContainsText('location')); }
  get createAccountBtn(){ return this.findByText('Create Account'); }
  get loginLink()       { return this.findByText('Login'); }

  // ─── Actions ───────────────────────────────────────────────

  async waitForLoad() {
    await this.waitForText('Create Account', 20000);
    return this;
  }

  async enterName(name) {
    logger.debug(`RegisterPage: enterName("${name}")`);
    const field = await this.nameField;
    await this.waitForVisible(field);
    await this.clearAndType(field, name);
    return this;
  }

  async enterEmail(email) {
    logger.debug(`RegisterPage: enterEmail("${email}")`);
    const field = await this.emailField;
    await this.clearAndType(field, email);
    return this;
  }

  async enterPhone(phone) {
    logger.debug(`RegisterPage: enterPhone("${phone}")`);
    const field = await this.phoneField;
    await this.clearAndType(field, phone);
    return this;
  }

  async enterPassword(password) {
    const field = await this.passwordField;
    await this.clearAndType(field, password);
    return this;
  }

  async enterConfirmPassword(password) {
    const field = await this.confirmField;
    await this.clearAndType(field, password);
    return this;
  }

  async tapCreateAccount() {
    logger.info('RegisterPage: tapping Create Account');
    const btn = await this.createAccountBtn;
    await this.scrollDown(300);
    await this.waitForClickable(btn);
    await btn.click();
    await this.pause(2500);
    return this;
  }

  /**
   * Full registration flow.
   */
  async register({ name, email, phone, password }) {
    await this.enterName(name);
    await this.enterEmail(email);
    await this.enterPhone(phone);
    await this.enterPassword(password);
    await this.enterConfirmPassword(password);
    await this.tapCreateAccount();
    return this;
  }

  // ─── Validation Assertions ─────────────────────────────────

  async getNameError()     { return (await this.findByContainsText('Name is required').catch(() => ({getText:()=>''})) ).getText().catch(() => ''); }
  async getEmailError()    { return (await this.findByContainsText('valid email').catch(() => ({getText:()=>''})) ).getText().catch(() => ''); }
  async getPhoneError()    { return (await this.findByContainsText('phone').catch(() => ({getText:()=>''})) ).getText().catch(() => ''); }
  async getPasswordError() { return (await this.findByContainsText('Password').catch(() => ({getText:()=>''})) ).getText().catch(() => ''); }

  async isDisplayed() {
    return this.textExists('Create Account', 5000);
  }
}

module.exports = RegisterPage;
