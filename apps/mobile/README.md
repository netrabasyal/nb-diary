# NB Diary app

Flutter app, shipped as a web app in V1.

```text
lib/
  app/        shell: app widget, router, registered modules
  platform/   shared by all modules: database, module contract (auth, sync, api from later phases)
  modules/    gym/ (first module), settings/ (shell-owned)
web/          index.html, manifest, service worker, Drift WebAssembly assets
```

See [docs/local-development.md](../../docs/local-development.md) for commands.
