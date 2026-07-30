'use strict';
const Mocha = require('mocha');
const ExcelReporter = require('./excel.reporter');
const logger = require('../utils/logger');
const path = require('path');
const fs = require('fs');
const moment = require('moment');

/**
 * MochaReporter — Hooks into Mocha events to collect test results
 * and generate the Excel report post-run.
 *
 * Usage: require this file in your mocha root hook plugin or global fixture.
 */
class MochaExcelPlugin {
  constructor() {
    this.results = [];
    this.failures = [];
    this.startTime = null;
  }

  attach(runner) {
    this.startTime = Date.now();

    runner.on('pass', (test) => {
      this.results.push({
        title: test.fullTitle(),
        module: test.parent?.title || 'General',
        status: 'PASS',
        durationMs: test.duration,
      });
    });

    runner.on('fail', (test, err) => {
      const screenshotDir = path.resolve(process.env.REPORT_DIR || './reports', 'failures');
      const screenshots = fs.existsSync(screenshotDir)
        ? fs.readdirSync(screenshotDir).filter(f => f.includes(test.title.replace(/[^a-z0-9]/gi, '_').substring(0, 20)))
        : [];
      const screenshotPath = screenshots.length > 0
        ? path.join(screenshotDir, screenshots[screenshots.length - 1])
        : 'N/A';

      this.results.push({
        title: test.fullTitle(),
        module: test.parent?.title || 'General',
        status: 'FAIL',
        durationMs: test.duration,
        error: err?.message,
      });

      this.failures.push({
        title: test.fullTitle(),
        error: err?.message || 'Unknown',
        screenshotPath,
      });
    });

    runner.on('pending', (test) => {
      this.results.push({
        title: test.fullTitle(),
        module: test.parent?.title || 'General',
        status: 'SKIP',
        durationMs: 0,
      });
    });

    runner.on('end', async () => {
      try {
        const durationSecs = ((Date.now() - this.startTime) / 1000).toFixed(1);
        const stats = {
          total:       this.results.length,
          passed:      this.results.filter(r => r.status === 'PASS').length,
          failed:      this.results.filter(r => r.status === 'FAIL').length,
          skipped:     this.results.filter(r => r.status === 'SKIP').length,
          durationSecs,
        };

        const reporter = new ExcelReporter();
        await reporter.generate(stats, this.results, this.failures, logger.executionLog);
        logger.info(`\n${'='.repeat(60)}\n📊 SUMMARY: Total=${stats.total} | ✅Pass=${stats.passed} | ❌Fail=${stats.failed} | ⏭Skip=${stats.skipped}\n${'='.repeat(60)}`);
      } catch (err) {
        logger.error(`Excel report generation failed: ${err.message}`);
      }
    });
  }
}

module.exports = MochaExcelPlugin;
