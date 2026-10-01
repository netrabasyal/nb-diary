// NB Diary service worker: keeps the app's own files available offline.
//
// - Page loads: network first, falling back to the cached copy when offline.
// - Other app files: served from cache, refreshed in the background.
// - API, sign-in and health routes are never cached.
//
// Flutter no longer generates a service worker, so this one is ours.
const CACHE = 'nb-diary-app-v1';

const PRECACHE = [
  './',
  'index.html',
  'flutter.js',
  'flutter_bootstrap.js',
  'main.dart.js',
  'manifest.json',
  'favicon.png',
  'sqlite3.wasm',
  'drift_worker.js',
];

const NEVER_CACHE = [/^\/v1\//, /^\/auth\//, /^\/health\//];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE).then((cache) => cache.addAll(PRECACHE)).then(() => self.skipWaiting()),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) => Promise.all(keys.filter((key) => key !== CACHE).map((key) => caches.delete(key))))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;
  if (NEVER_CACHE.some((pattern) => pattern.test(url.pathname))) return;

  if (request.mode === 'navigate') {
    event.respondWith(networkFirst(request));
  } else {
    event.respondWith(cacheFirstThenRefresh(event, request));
  }
});

async function networkFirst(request) {
  const cache = await caches.open(CACHE);
  try {
    const response = await fetch(request);
    if (response.ok) await cache.put('index.html', response.clone());
    return response;
  } catch (error) {
    // Every app route renders the same index.html, so one cached copy serves them all.
    const cached = await cache.match('index.html');
    if (cached) return cached;
    throw error;
  }
}

async function cacheFirstThenRefresh(event, request) {
  const cache = await caches.open(CACHE);
  const cached = await cache.match(request);
  const refresh = fetch(request)
    .then((response) => {
      if (response.ok) return cache.put(request, response.clone()).then(() => response);
      return response;
    })
    .catch(() => undefined);

  if (cached) {
    event.waitUntil(refresh);
    return cached;
  }
  const response = await refresh;
  return response ?? Response.error();
}
