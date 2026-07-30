'use strict';
const BasePage = require('./base.page');
const logger = require('../utils/logger');

/**
 * LoginPage — AgriLink login screen.
 * Route: /login
 *
 * Fields (from login_screen.dart):
 *  - Email (AppTextField with label 'Email', hint 'you@example.com')
 *  - Password (AppTextField with label 'Password', hint '••••••••')
 *  - Sign In button (AppButton with label 'Sign In')
 *  - Forgot Password link
 *  - Register link
 *
 * Validation (from AppValidators.email + inline validators):
 *  - Email required + valid format
 *  - Password required
 */
class LoginPage extends BasePage {
  // ─── Locators ──────────────────────────────────────────────

  get emailField() {
    return this.isFlutter
      ? this.findByText('you@example.com').catch(() => this.findByContainsText('Email'))
      : this.driver.$('//android.widget.EditText[@hint="you@example.com"]');
  }

  get passwordField() {
    return this.isFlutter
      ? this.findByText('••••••••').catch(() => this.findByContainsText('Password'))
      : this.driver.$('(//android.widget.EditText)[2]');
  }

  get signInButton() {
    return this.findByText('Sign In');
  }

  get forgotPasswordLink() {
    return this.findByText('Forgot password?');
  }

  get registerLink() {
    return this.findByText('Register');
  }

  get errorBanner() {
    return this.findByText('Authentication Failed');
  }

  get visibilityToggle() {
    return this.findByContainsText('visibility').catch(
      () => this.driver.$('//android.widget.ImageButton')
    );
  }

  // ─── Actions ───────────────────────────────────────────────

  async waitForLoad() {
    logger.debug('LoginPage: waiting for load');
    await this.waitForText('Sign In', 20000);
    return this;
  }

  async enterEmail(email) {
    logger.debug(`LoginPage: enterEmail("${email}")`);
    const field = await this.emailField;
    await this.waitForVisible(field);
    await this.clearAndType(field, email);
    return this;
  }

  async enterPassword(password) {
    logger.debug(`LoginPage: enterPassword("****")`);
    const field = await this.passwordField;
    await this.waitForVisible(field);
    await this.clearAndType(field, password);
    return this;
  }

  async tapSignIn() {
    logger.info('LoginPage: tapping Sign In');
    const btn = await this.signInButton;
    await this.waitForClickable(btn);
    await btn.click();
    await this.pause(2000);
    return this;
  }

  async tapForgotPassword() {
    const link = await this.forgotPasswordLink;
    await this.waitForClickable(link);
    await link.click();
  }

  async tapRegister() {
    const link = await this.registerLink;
    await this.waitForClickable(link);
    await link.click();
  }

  async togglePasswordVisibility() {
    const icon = await this.visibilityToggle;
    await icon.click();
  }

  /**
   * Full login action.
   */
  async login(email, password) {
    await this.enterEmail(email);
    await this.enterPassword(password);
    await this.tapSignIn();
    return this;
  }

  // ─── Validation Assertions ─────────────────────────────────

  async getEmailValidationError() {
    const emailError = await this.findByContainsText('valid email').catch(
      () => this.findByContainsText('Email is required')
    );
    return emailError.getText().catch(() => '');
  }

  async getPasswordValidationError() {
    const passError = await this.findByContainsText('Password is required');
    return passError.getText().catch(() => '');
  }

  async getErrorBannerText() {
    const banner = await this.findByContainsText('Authentication Failed');
    return banner.getText().catch(() => '');
  }

  async isErrorBannerVisible() {
    return this.textExists('Authentication Failed', 8000);
  }

  async isSignInButtonDisplayed() {
    return this.textExists('Sign In', 5000);
  }

  async isDisplayed() {
    return this.isSignInButtonDisplayed();
  }
}

module.exports = LoginPage;
