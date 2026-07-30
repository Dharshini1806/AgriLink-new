'use strict';
const BasePage = require('./base.page');
const logger = require('../utils/logger');

/**
 * ProductFeedPage — AgriLink home/product feed screen.
 * Route: /home
 * Role: Buyer
 */
class ProductFeedPage extends BasePage {
  // ─── Locators ──────────────────────────────────────────────

  get searchBar()     { return this.findByContainsText('Search').catch(() => this.driver.$('//android.widget.EditText')); }
  get filterBtn()     { return this.findByContainsText('Filter'); }
  get cartIcon()      { return this.driver.$('//android.widget.ImageButton[@content-desc="Cart"]').catch(() => this.findByContainsText('cart')); }
  get firstProduct()  { return this.driver.$('(//android.widget.ImageView)[1]'); }
  get wishlistIcons() { return this.driver.$$('//*[@content-desc="wishlist" or @content-desc="Add to wishlist"]'); }
  get navHome()       { return this.driver.$('//*[@content-desc="Home"]').catch(() => this.findByText('Home')); }
  get navOrders()     { return this.driver.$('//*[@content-desc="Orders"]').catch(() => this.findByText('Orders')); }
  get navProfile()    { return this.driver.$('//*[@content-desc="Profile"]').catch(() => this.findByText('Profile')); }
  get navSearch()     { return this.driver.$('//*[@content-desc="Search"]').catch(() => this.findByText('Search')); }
  get navRecipe()     { return this.driver.$('//*[@content-desc="Recipe"]').catch(() => this.findByText('Recipe')); }

  // ─── Actions ───────────────────────────────────────────────

  async waitForLoad() {
    logger.debug('ProductFeedPage: waiting for load');
    await this.pause(3000); // wait for network data
    return this;
  }

  async searchFor(query) {
    logger.info(`ProductFeedPage: searching for "${query}"`);
    const bar = await this.searchBar;
    await this.waitForVisible(bar);
    await bar.click();
    await this.clearAndType(bar, query);
    await this.driver.keys(['Enter']);
    await this.pause(2000);
    return this;
  }

  async tapFirstProduct() {
    logger.info('ProductFeedPage: tapping first product');
    const el = await this.firstProduct;
    await this.waitForVisible(el);
    await el.click();
    await this.pause(1500);
    return this;
  }

  async tapCart() {
    const icon = await this.cartIcon;
    await icon.click();
    await this.pause(1500);
  }

  async addFirstProductToWishlist() {
    const icons = await this.wishlistIcons;
    if (icons.length > 0) {
      await icons[0].click();
      await this.pause(1000);
    }
  }

  async navigateTo(tab) {
    const navMap = {
      home:    this.navHome,
      orders:  this.navOrders,
      profile: this.navProfile,
      search:  this.navSearch,
      recipe:  this.navRecipe,
    };
    const el = await navMap[tab.toLowerCase()];
    await (await el).click();
    await this.pause(1500);
  }

  // ─── Assertions ──────────────────────────────────────────

  async isDisplayed() {
    return this.textExists('AgriLink', 8000)
      || this.exists(await this.navHome);
  }

  async hasProducts() {
    const products = await this.driver.$$('//android.widget.ImageView');
    return products.length > 0;
  }
}

module.exports = ProductFeedPage;
