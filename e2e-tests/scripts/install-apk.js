'use strict';
const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

/**
 * install-apk.js — Installs AgriLink APK onto connected Android device/emulator
 * before running E2E tests. Validates device connection and APK existence.
 */

const APK_PATH = path.resolve(process.env.APK_PATH || './app/app-release.apk');
const APP_PACKAGE = process.env.APP_PACKAGE || 'com.agrilink.app';

function run(cmd, silent = false) {
  try {
    const output = execSync(cmd, { encoding: 'utf8', timeout: 120000 });
    if (!silent) console.log(output.trim());
    return output.trim();
  } catch (err) {
    console.error(`Command failed: ${cmd}`);
    console.error(err.stderr || err.message);
    process.exit(1);
  }
}

console.log('\n🌾 AgriLink APK Installer\n' + '='.repeat(40));

// 1. Check ADB is available
console.log('🔍 Checking ADB...');
run('adb version', true);
console.log('✅ ADB found');

// 2. Check device connected
console.log('\n🔍 Checking device...');
const devices = run('adb devices', true);
const deviceLines = devices.split('\n').slice(1).filter(l => l.includes('\tdevice'));
if (deviceLines.length === 0) {
  console.error('❌ No Android device/emulator connected. Start an emulator or connect a device.');
  process.exit(1);
}
console.log(`✅ Device found: ${deviceLines[0].split('\t')[0]}`);

// 3. Check APK exists
console.log(`\n🔍 Checking APK: ${APK_PATH}`);
if (!fs.existsSync(APK_PATH)) {
  console.error(`❌ APK not found at: ${APK_PATH}`);
  console.error('→ Build your Flutter APK first: flutter build apk --release');
  process.exit(1);
}
const stat = fs.statSync(APK_PATH);
console.log(`✅ APK found (${(stat.size / 1024 / 1024).toFixed(1)} MB)`);

// 4. Uninstall existing (optional clean install)
console.log(`\n📦 Uninstalling existing ${APP_PACKAGE}...`);
try { run(`adb uninstall ${APP_PACKAGE}`, true); console.log('✅ Previous install removed'); }
catch { console.log('ℹ️  App not previously installed'); }

// 5. Install APK
console.log(`\n📲 Installing APK...`);
run(`adb install -r -g "${APK_PATH}"`);
console.log(`✅ APK installed: ${APP_PACKAGE}`);

// 6. Grant permissions
console.log('\n🔑 Granting permissions...');
const permissions = [
  'android.permission.READ_EXTERNAL_STORAGE',
  'android.permission.WRITE_EXTERNAL_STORAGE',
  'android.permission.CAMERA',
  'android.permission.ACCESS_FINE_LOCATION',
  'android.permission.ACCESS_COARSE_LOCATION',
  'android.permission.POST_NOTIFICATIONS',
  'android.permission.INTERNET',
];
permissions.forEach(perm => {
  try { run(`adb shell pm grant ${APP_PACKAGE} ${perm}`, true); }
  catch { /* some perms not grantable via adb */ }
});
console.log('✅ Permissions granted');

console.log('\n🎉 Installation complete. Ready to run E2E tests.\n');
