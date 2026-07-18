const {test, expect} = require('@playwright/test');
const AxeBuilder = require('@axe-core/playwright').default;
const {pathToFileURL} = require('node:url');
const path = require('node:path');

const fixture = name => pathToFileURL(path.join(__dirname, 'fixtures', name)).href;

for (const [name, url] of [
    ['login', fixture('login.html')],
    ['tenant-a', `${fixture('shell.html')}?tenant=a`],
    ['tenant-b', `${fixture('shell.html')}?tenant=b`],
    ['components', fixture('components.html')],
]) {
    test(`${name} is accessible and visually stable`, async ({page}, testInfo) => {
        await page.goto(url);
        await expect(page.locator('body')).toBeVisible();
        const results = await new AxeBuilder({page}).analyze();
        expect(results.violations).toEqual([]);
        const screenshot = await page.screenshot({animations: 'disabled', fullPage: true});
        expect(screenshot.byteLength).toBeGreaterThan(5000);
        await testInfo.attach(`${name}-${testInfo.project.name}.png`, {body: screenshot, contentType: 'image/png'});
        const viewport = page.viewportSize();
        const body = await page.locator('body').boundingBox();
        expect(body.width).toBeLessThanOrEqual(viewport.width);
    });
}

test('mobile drawer transfers focus and closes with Escape', async ({page}, testInfo) => {
    test.skip(testInfo.project.name !== 'mobile');
    await page.goto(fixture('shell.html'));
    const menu = page.getByRole('button', {name: 'Menu'});
    await menu.click();
    await expect(page.getByRole('link', {name: 'Home'})).toBeFocused();
    await page.keyboard.press('Escape');
    await expect(menu).toBeFocused();
    await expect(menu).toHaveAttribute('aria-expanded', 'false');
});

test('dialog traps focus, closes with Escape and restores its trigger', async ({page}, testInfo) => {
    test.skip(testInfo.project.name !== 'desktop');
    await page.goto(fixture('dialog.html'));
    const trigger = page.getByRole('button', {name: 'Open account dialog'});
    await trigger.click();
    await expect(page.getByRole('dialog')).toBeVisible();
    await page.keyboard.press('Shift+Tab');
    const focusRemainsInDialog = await page.evaluate(() => {
        const dialog = document.querySelector('#dialog');
        return document.activeElement === dialog || dialog.contains(document.activeElement);
    });
    expect(focusRemainsInDialog).toBe(true);
    await page.keyboard.press('Escape');
    await expect(page.getByRole('dialog')).toBeHidden();
    await expect(trigger).toBeFocused();
});

test('login reflows without horizontal overlap at a 200 percent zoom equivalent', async ({page}, testInfo) => {
    test.skip(testInfo.project.name !== 'desktop');
    await page.setViewportSize({width: 320, height: 720});
    await page.goto(fixture('login.html'));
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    expect(overflow).toBeLessThanOrEqual(1);
    await expect(page.getByRole('button', {name: 'Sign in'})).toBeVisible();
});
