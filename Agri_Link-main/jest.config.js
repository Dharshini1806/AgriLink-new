module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/tests/**/*.test.js'],
  collectCoverageFrom: [
    'src/utils/**/*.js',
    'src/modules/**/*.service.js',
  ],
  coverageThreshold: {
    global: { lines: 70 },
  },
};
