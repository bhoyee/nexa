const {defineConfig, devices} = require('@playwright/test');

module.exports = defineConfig({
    testDir: './tests/browser',
    outputDir: './test-results/browser',
    reporter: [['line'], ['html', {outputFolder: 'test-results/report', open: 'never'}]],
    use: {
        browserName: 'chromium',
        colorScheme: 'light',
        locale: 'en-GB',
        screenshot: 'only-on-failure',
        trace: 'retain-on-failure',
    },
    projects: [
        {name: 'desktop', use: {viewport: {width: 1440, height: 900}}},
        {name: 'tablet', use: {viewport: {width: 768, height: 1024}}},
        {name: 'tablet-landscape', use: {viewport: {width: 1024, height: 768}}},
        {name: 'mobile', use: {...devices['iPhone 13']}},
        {name: 'mobile-landscape', use: {viewport: {width: 844, height: 390}, isMobile: true, hasTouch: true}},
    ],
});
