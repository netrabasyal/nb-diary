import { defineConfig, devices } from '@playwright/test';

// Set PW_CHROMIUM_PATH to use an already-installed Chromium instead of downloading one.
const chromiumPath = process.env.PW_CHROMIUM_PATH;

export default defineConfig({
  testDir: './specs',
  timeout: 120_000,
  expect: { timeout: 30_000 },
  retries: 0,
  reporter: [['list']],
  use: {
    baseURL: 'http://localhost:8085',
    trace: 'retain-on-failure',
  },
  webServer: {
    command: 'node serve.mjs',
    url: 'http://localhost:8085',
    reuseExistingServer: !process.env.CI,
  },
  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        ...(chromiumPath ? { launchOptions: { executablePath: chromiumPath } } : {}),
      },
    },
    // WebKit is Safari's engine; it runs in CI where Playwright installs it.
    ...(process.env.CI ? [{ name: 'webkit', use: { ...devices['iPhone 15'] } }] : []),
  ],
});
