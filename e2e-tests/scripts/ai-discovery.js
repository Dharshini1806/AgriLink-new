'use strict';
require('dotenv').config();
const DriverFactory = require('../config/driver.factory');
const logger = require('../utils/logger');
const fs = require('fs');
const path = require('path');

/**
 * AI Discovery Module — Automatically analyzes the Flutter app:
 * 1. Connects to device and launches app
 * 2. Crawls screen-by-screen by capturing widget tree / page source
 * 3. Detects interactive widgets (buttons, text fields, etc.)
 * 4. Generates test scenario skeletons
 * 5. Outputs ai-discovered-scenarios.json
 */

const OUTPUT_PATH = path.resolve('./reports/ai-discovered-scenarios.json');

const WIDGET_PATTERNS = {
  buttons:    [/ElevatedButton|TextButton|IconButton|FloatingActionButton/gi, /Sign In|Register|Submit|Add|Save|Cancel|OK|Confirm/gi],
  textFields: [/TextField|TextFormField|EditText/gi, /email|password|name|phone|search|hint/gi],
  navigation: [/BottomNavigationBar|TabBar|Drawer|NavigationBar/gi],
  dialogs:    [/AlertDialog|BottomSheet|Dialog|SnackBar/gi],
  lists:      [/ListView|GridView|RecyclerView|ScrollView/gi],
};

function extractWidgets(pageSource) {
  const discovered = {
    buttons: [],
    textFields: [],
    navigation: [],
    dialogs: [],
    lists: [],
    texts: [],
  };

  // Extract text elements
  const textMatches = pageSource.match(/text="([^"]{2,60})"/g) || [];
  discovered.texts = [...new Set(textMatches.map(m => m.replace(/text="|"/g, '')))].slice(0, 30);

  // Extract content-desc (accessibility labels / ValueKeys)
  const descMatches = pageSource.match(/content-desc="([^"]{2,80})"/g) || [];
  discovered.accessibilityLabels = [...new Set(descMatches.map(m => m.replace(/content-desc="|"/g, '')))];

  // Detect buttons by common text patterns
  const buttonTexts = ['Sign In', 'Register', 'Login', 'Create Account', 'Add Product', 'Submit', 'Save', 'Continue', 'Cancel', 'OK', 'Confirm'];
  discovered.buttons = discovered.texts.filter(t => buttonTexts.some(bt => t.includes(bt)));

  // Detect text fields by hint
  const hintMatches = pageSource.match(/hint="([^"]{2,60})"/g) || [];
  discovered.textFields = [...new Set(hintMatches.map(m => m.replace(/hint="|"/g, '')))];

  return discovered;
}

function generateScenarioSkeleton(screenName, widgets) {
  const scenarios = [];

  if (widgets.buttons.length > 0) {
    widgets.buttons.forEach(btn => {
      scenarios.push({
        id: `AI-${screenName.toUpperCase()}-${btn.replace(/\s/g, '_')}`,
        type: 'tap',
        description: `Tap "${btn}" button on ${screenName} screen`,
        locator: `findByText('${btn}')`,
        action: 'click',
        assertion: 'screen_transition or success_message',
      });
    });
  }

  if (widgets.textFields.length > 0) {
    scenarios.push({
      id: `AI-${screenName.toUpperCase()}-FORM-VALIDATION`,
      type: 'form_validation',
      description: `Submit ${screenName} form with empty fields`,
      fields: widgets.textFields,
      action: 'submit_empty_form',
      assertion: 'validation_errors_visible',
    });
  }

  if (widgets.texts.length > 0) {
    scenarios.push({
      id: `AI-${screenName.toUpperCase()}-VISIBILITY`,
      type: 'visibility',
      description: `Verify key elements visible on ${screenName} screen`,
      expectedTexts: widgets.texts.slice(0, 5),
      action: 'verify_text_visible',
      assertion: 'all_texts_present',
    });
  }

  return scenarios;
}

async function discoverScreens() {
  const allScenarios = [];
  const discoveredData = { screens: [], scenarios: [], generatedAt: new Date().toISOString() };

  try {
    logger.info('AI Discovery: Starting app session...');
    await DriverFactory.createDriver();
    const driver = DriverFactory.getDriver();

    await new Promise(resolve => setTimeout(resolve, 3000));

    // ── Screen 1: Role Selection ───────────────────────────
    logger.info('AI Discovery: Analyzing Role Selection screen...');
    let pageSource = await driver.getPageSource();
    let widgets = extractWidgets(pageSource);
    discoveredData.screens.push({ name: 'RoleSelection', widgets });
    allScenarios.push(...generateScenarioSkeleton('RoleSelection', widgets));

    // ── Try to navigate to Login ───────────────────────────
    try {
      const buyerEl = await driver.$('//*[contains(@text, "Buyer")]');
      await buyerEl.click();
      await new Promise(r => setTimeout(r, 1500));

      const continueEl = await driver.$('//*[@text="Continue"]').catch(() => null);
      if (continueEl) await continueEl.click();
      await new Promise(r => setTimeout(r, 2000));

      logger.info('AI Discovery: Analyzing Login screen...');
      pageSource = await driver.getPageSource();
      widgets = extractWidgets(pageSource);
      discoveredData.screens.push({ name: 'Login', widgets });
      allScenarios.push(...generateScenarioSkeleton('Login', widgets));
    } catch (e) {
      logger.warn(`AI Discovery: Could not navigate to Login — ${e.message}`);
    }

    discoveredData.scenarios = allScenarios;
    discoveredData.summary = {
      totalScreensAnalyzed: discoveredData.screens.length,
      totalScenariosGenerated: allScenarios.length,
    };

    // Write output
    const outDir = path.dirname(OUTPUT_PATH);
    if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
    fs.writeFileSync(OUTPUT_PATH, JSON.stringify(discoveredData, null, 2), 'utf8');

    logger.info(`\n✅ AI Discovery Complete!`);
    logger.info(`   Screens analyzed: ${discoveredData.screens.length}`);
    logger.info(`   Scenarios generated: ${allScenarios.length}`);
    logger.info(`   Output: ${OUTPUT_PATH}`);

    await DriverFactory.destroyDriver();
    return discoveredData;
  } catch (err) {
    logger.error(`AI Discovery failed: ${err.message}`);
    await DriverFactory.destroyDriver().catch(() => {});
    throw err;
  }
}

discoverScreens().catch(err => {
  console.error(err);
  process.exit(1);
});

module.exports = { discoverScreens, extractWidgets, generateScenarioSkeleton };
