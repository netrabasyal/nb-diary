import { expect, test, type Page } from '@playwright/test';

// Flutter draws to a canvas. Turning on its accessibility tree exposes the
// on-screen text as DOM nodes, the same nodes VoiceOver reads.
async function enableSemantics(page: Page) {
  const placeholder = page.locator('flt-semantics-placeholder');
  await placeholder.waitFor({ state: 'attached' });
  await placeholder.evaluate((el: HTMLElement) => el.click());
}

async function openApp(page: Page, path = '/') {
  await page.goto(path);
  await enableSemantics(page);
  await expect(page.getByText('Start workout')).toBeVisible();
}

async function timesOpened(page: Page): Promise<number> {
  await page.getByRole('tab', { name: 'Settings' }).click();
  const row = page.getByText(/Times opened/);
  await expect(row).toBeVisible();
  const text = (await row.textContent()) ?? '';
  const match = text.match(/(\d+)\s*$/);
  if (!match) throw new Error(`No launch count in "${text}"`);
  return Number(match[1]);
}

test('opens offline and keeps data on the device across reloads', async ({ page, context }) => {
  await openApp(page);
  expect(await timesOpened(page)).toBe(1);

  // Wait until the service worker controls the page, so files are cached.
  await page.evaluate(async () => {
    await navigator.serviceWorker.ready;
    if (!navigator.serviceWorker.controller) {
      await new Promise((resolve) =>
        navigator.serviceWorker.addEventListener('controllerchange', resolve, { once: true }),
      );
    }
  });

  await openApp(page);
  expect(await timesOpened(page)).toBe(2);

  await context.setOffline(true);
  await openApp(page, '/gym');
  expect(await timesOpened(page)).toBe(3);
});

test('sends the headers Drift needs for its fastest storage', async ({ page }) => {
  const response = await page.goto('/');
  expect(response?.headers()['cross-origin-opener-policy']).toBe('same-origin');
  expect(response?.headers()['cross-origin-embedder-policy']).toBe('require-corp');
});
