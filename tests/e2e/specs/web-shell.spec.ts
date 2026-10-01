import type { Server } from 'node:http';
import { expect, test, type Page } from '@playwright/test';
import { startServer } from '../serve.mjs';

// Flutter draws to a canvas. Turning on its accessibility tree exposes the
// on-screen text as DOM nodes, the same nodes VoiceOver reads.
async function enableSemantics(page: Page) {
  const placeholder = page.locator('flt-semantics-placeholder');
  await placeholder.waitFor({ state: 'attached' });
  await placeholder.evaluate((el: HTMLElement) => el.click());
}

async function openApp(page: Page, url: string) {
  await page.goto(url);
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

async function stop(server: Server) {
  server.closeAllConnections();
  await new Promise((resolve) => server.close(resolve));
}

test('opens offline and keeps data on the device across reloads', async ({ page }, testInfo) => {
  // A dedicated server per browser, so going "offline" means really stopping it:
  // the app must then load from the service worker's cache, as on a phone in the gym.
  const port = 8090 + testInfo.parallelIndex;
  const origin = `http://localhost:${port}`;
  const server = await startServer(port);

  try {
    await openApp(page, `${origin}/`);
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

    await openApp(page, `${origin}/`);
    expect(await timesOpened(page)).toBe(2);
  } finally {
    await stop(server);
  }

  await openApp(page, `${origin}/gym`);
  expect(await timesOpened(page)).toBe(3);
});

test('sends the headers Drift needs for its fastest storage', async ({ page }) => {
  const response = await page.goto('/');
  expect(response?.headers()['cross-origin-opener-policy']).toBe('same-origin');
  expect(response?.headers()['cross-origin-embedder-policy']).toBe('require-corp');
});
