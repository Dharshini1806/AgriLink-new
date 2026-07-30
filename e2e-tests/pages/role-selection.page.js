'use strict';
const BasePage = require('./base.page');
const logger = require('../utils/logger');

/**
 * RoleSelectionPage — AgriLink app entry screen.
 * Route: /role-select
 * Widgets: Role cards for "Buyer" and "Seller/Farmer"
 */
class RoleSelectionPage extends BasePage {
  // ─── Locators ────────────────────────────────────────────
  get buyerRoleCard()  { return this.findByText('Buyer').catch(() => this.findByContainsText('Buyer')); }
  get sellerRoleCard() { return this.findByText('Farmer').catch(() => this.findByContainsText('Farmer')); }
  get continueBtn()    { return this.findByText('Continue'); }
  get appTitle()       { return this.findByContainsText('AgriLink'); }

  // ─── Actions ─────────────────────────────────────────────

  async waitForLoad() {
    logger.debug('RoleSelectionPage: waiting for load');
    await this.pause(2000);
    return this;
  }

  async selectBuyerRole() {
    logger.info('RoleSelectionPage: selecting Buyer role');
    const card = await this.findByContainsText('Buyer');
    await this.waitForVisible(card);
    await card.click();
    return this;
  }

  async selectSellerRole() {
    logger.info('RoleSelectionPage: selecting Seller/Farmer role');
    const card = await this.findByContainsText('Farmer');
    await this.waitForVisible(card);
    await card.click();
    return this;
  }

  async tapContinue() {
    const btn = await this.continueBtn;
    await this.waitForClickable(btn);
    await btn.click();
  }

  // ─── Assertions ──────────────────────────────────────────

  async isDisplayed() {
    return this.textExists('AgriLink', 5000)
      || this.textExists('Buyer', 5000);
  }
}

module.exports = RoleSelectionPage;
