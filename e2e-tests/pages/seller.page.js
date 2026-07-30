'use strict';
const BasePage = require('./base.page');
const logger = require('../utils/logger');

/**
 * SellerDashboardPage — AgriLink Seller Dashboard screen.
 * Route: /seller/dashboard
 */
class SellerDashboardPage extends BasePage {
  get addProductBtn()   { return this.findByContainsText('Add Product').catch(() => this.findByContainsText('+')); }
  get revenueCard()     { return this.findByContainsText('Revenue').catch(() => this.findByContainsText('revenue')); }
  get ordersCard()      { return this.findByContainsText('Orders'); }
  get productsTab()     { return this.findByContainsText('Products').catch(() => this.driver.$('//*[@content-desc="Products"]')); }
  get analyticsTab()    { return this.findByContainsText('Analytics'); }
  get profileTab()      { return this.findByContainsText('Profile'); }

  async waitForLoad() {
    await this.pause(3000);
    return this;
  }

  async tapAddProduct() {
    logger.info('SellerDashboardPage: tapping Add Product');
    const btn = await this.addProductBtn;
    await this.waitForClickable(btn);
    await btn.click();
    await this.pause(1500);
    return this;
  }

  async tapProductsTab() {
    const tab = await this.productsTab;
    await tab.click();
    await this.pause(1500);
  }

  async tapAnalyticsTab() {
    const tab = await this.analyticsTab;
    await tab.click();
    await this.pause(1500);
  }

  async isDisplayed() {
    return this.textExists('Dashboard', 8000) || this.textExists('Revenue', 8000);
  }
}

// ──────────────────────────────────────────────────────────────

/**
 * AddProductPage — Seller Add/Edit Product screen.
 * Route: /seller/add-product
 */
class AddProductPage extends BasePage {
  get nameField()     { return this.driver.$('(//android.widget.EditText)[1]'); }
  get priceField()    { return this.driver.$('(//android.widget.EditText)[2]'); }
  get stockField()    { return this.driver.$('(//android.widget.EditText)[3]'); }
  get descField()     { return this.driver.$('(//android.widget.EditText)[4]'); }
  get categoryDropdown() { return this.findByContainsText('Category'); }
  get submitBtn()     { return this.findByContainsText('Add Product').catch(() => this.findByContainsText('Save')); }
  get imagePickerBtn(){ return this.findByContainsText('Image').catch(() => this.findByContainsText('Photo')); }

  async waitForLoad() {
    await this.waitForText('Add Product', 20000).catch(() => this.waitForText('Product', 20000));
    return this;
  }

  async enterProductName(name) {
    const f = await this.nameField;
    await this.clearAndType(f, name);
    return this;
  }

  async enterPrice(price) {
    const f = await this.priceField;
    await this.clearAndType(f, String(price));
    return this;
  }

  async enterStock(stock) {
    const f = await this.stockField;
    await this.clearAndType(f, String(stock));
    return this;
  }

  async enterDescription(desc) {
    const f = await this.descField;
    await this.scrollDown(400);
    await this.clearAndType(f, desc);
    return this;
  }

  async submitProduct() {
    logger.info('AddProductPage: submitting product');
    const btn = await this.submitBtn;
    await this.scrollDown(600);
    await this.waitForClickable(btn);
    await btn.click();
    await this.pause(3000);
    return this;
  }

  async isDisplayed() {
    return this.textExists('Add Product', 5000);
  }
}

module.exports = { SellerDashboardPage, AddProductPage };
