// Kept out of index.html so the Content Security Policy needs no inline scripts.
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('nb_service_worker.js');
  });
}
// Ask the browser not to clear this app's storage under pressure.
if (navigator.storage && navigator.storage.persist) {
  navigator.storage.persist();
}
