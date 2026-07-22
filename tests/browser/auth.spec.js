const {test, expect} = require('@playwright/test');
const AxeBuilder = require('@axe-core/playwright').default;
const {pathToFileURL} = require('node:url');
const path = require('node:path');

const fixture = pathToFileURL(path.join(__dirname, 'fixtures', 'auth.html')).href;
const states = ['login', 'signup', 'verify', 'recovery', 'reset', 'success', 'expired', 'failure'];

for (const state of states) {
    test(`authentication state ${state} is accessible and responsive`, async ({page}, testInfo) => {
        await page.goto(`${fixture}?state=${state}&plan=growth`);
        await expect(page.locator(`[data-state="${state}"]`)).toBeVisible();
        expect((await new AxeBuilder({page}).analyze()).violations).toEqual([]);
        expect(await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth)).toBe(true);
        const screenshot = await page.screenshot({animations: 'disabled', fullPage: true});
        expect(screenshot.byteLength).toBeGreaterThan(4000);
        expect(screenshot).toMatchSnapshot(`auth-${state}-${testInfo.project.name}.png`);
        await testInfo.attach(`auth-${state}-${testInfo.project.name}.png`, {body: screenshot, contentType: 'image/png'});
    });
}

test('selected plan survives the account creation entry point', async ({page}) => {
    await page.goto(`${fixture}?state=signup&plan=scale`);
    await expect(page.locator('[data-signup] [name="plan"]')).toHaveValue('scale');
});

test('social controls are absent unless a provider is enabled', async ({page}) => {
    await page.goto(`${fixture}?state=login`);
    await expect(page.locator('[data-social]')).toBeHidden();
    await page.goto(`${fixture}?state=login&provider=google`);
    await expect(page.getByRole('button', {name: 'Continue with Google'})).toBeVisible();
});

test('email verification and recovery expose clear neutral states', async ({page}) => {
    await page.goto(`${fixture}?state=verify`);
    await page.getByLabel('Verification code').fill('12345678');
    await page.getByRole('button', {name: 'Verify and continue'}).click();
    await expect(page.getByRole('heading', {name: 'Workspace active'})).toBeVisible();

    await page.goto(`${fixture}?state=recovery`);
    const recovery = page.locator('[data-state="recovery"]');
    await recovery.getByLabel('Email address').fill('sample@example.test');
    await recovery.getByRole('button', {name: 'Send reset instructions'}).click();
    await expect(page.getByRole('status')).toContainText('If the email matches an account');
});
test('progressive signup states preserve keyboard and visual layout boundaries', async ({page}, testInfo) => {
    for (const state of ['signup-method', 'signup-profile']) {
        await page.goto(`${fixture}?state=${state}&plan=scale&provider=google`);
        await expect(page.locator(`[data-state="${state}"]`)).toBeVisible();
        expect((await new AxeBuilder({page}).analyze()).violations).toEqual([]);
        expect(await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth)).toBe(true);

        const bounds = await page.locator(`[data-state="${state}"]`).boundingBox();
        const viewport = page.viewportSize();
        expect(bounds).not.toBeNull();
        expect(bounds.x).toBeGreaterThanOrEqual(0);
        expect(bounds.x + bounds.width).toBeLessThanOrEqual(viewport.width);

        const screenshot = await page.screenshot({animations: 'disabled', fullPage: true});
        expect(screenshot.byteLength).toBeGreaterThan(4000);
        await testInfo.attach(`${state}-${testInfo.project.name}.png`, {body: screenshot, contentType: 'image/png'});
    }
});

test('progressive email signup carries the selected plan into workspace details', async ({page}) => {
    await page.goto(`${fixture}?state=signup-method&plan=scale`);
    await page.locator('[data-progressive-start]').getByLabel('Work email').fill('owner@example.test');
    await page.getByRole('button', {name: 'Continue with email'}).click();
    await expect(page.locator('[data-state="signup-profile"]')).toBeVisible();
    await expect(page.locator('[data-progressive-profile] [name="plan"]')).toHaveValue('scale');
});