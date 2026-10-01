// Serves the built web app (apps/mobile/build/web) the way production will:
// cross-origin isolation headers (needed for Drift's fastest browser storage),
// correct MIME types, and every unknown path falling back to index.html.
import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { extname, join, normalize, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(fileURLToPath(new URL('../../apps/mobile/build/web/', import.meta.url)));

const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.frag': 'application/octet-stream',
  '.bin': 'application/octet-stream',
};

const securityHeaders = {
  'Cross-Origin-Opener-Policy': 'same-origin',
  'Cross-Origin-Embedder-Policy': 'require-corp',
  'Cross-Origin-Resource-Policy': 'same-origin',
  'X-Content-Type-Options': 'nosniff',
};

async function resolveFile(urlPath) {
  const candidate = normalize(join(root, decodeURIComponent(urlPath)));
  if (!candidate.startsWith(root)) return null;
  try {
    const info = await stat(candidate);
    return info.isDirectory() ? join(candidate, 'index.html') : candidate;
  } catch {
    return null;
  }
}

export function startServer(port) {
  const server = createServer(async (req, res) => {
    const { pathname } = new URL(req.url, 'http://localhost');
    const file = (await resolveFile(pathname)) ?? join(root, 'index.html');
    try {
      const body = await readFile(file);
      res.writeHead(200, {
        ...securityHeaders,
        'Content-Type': types[extname(file)] ?? 'application/octet-stream',
        'Cache-Control': 'no-cache',
      });
      res.end(body);
    } catch {
      res.writeHead(404, securityHeaders);
      res.end('Not found');
    }
  });
  return new Promise((resolveStarted) => server.listen(port, () => resolveStarted(server)));
}

// `node serve.mjs` serves on PORT (default 8085) until stopped.
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const port = Number(process.env.PORT ?? 8085);
  await startServer(port);
  console.log(`Serving ${root} on http://localhost:${port}`);
}
