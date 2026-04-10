// ═══════════════════════════════════
// Beyma Flow — Service Worker v6
// ═══════════════════════════════════
const CACHE_NAME = 'beymaflow-v6';

// Fichiers à mettre en cache
const STATIC_ASSETS = [
  './',
  './index.html',
  './manifest.json'
];

// ── INSTALL ──
self.addEventListener('install', e => {
  console.log('[SW] Installing Beyma Flow v6...');
  e.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(STATIC_ASSETS))
      .then(() => self.skipWaiting())
  );
});

// ── ACTIVATE ──
self.addEventListener('activate', e => {
  console.log('[SW] Activating...');
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(
        keys
          .filter(k => k !== CACHE_NAME)
          .map(k => {
            console.log('[SW] Deleting old cache:', k);
            return caches.delete(k);
          })
      )
    ).then(() => self.clients.claim())
  );
});

// ── FETCH ──
self.addEventListener('fetch', e => {
  const url = e.request.url;

  // Ne pas intercepter les appels API externes
  if (
    url.includes('firebase') ||
    url.includes('firebaseio.com') ||
    url.includes('googleapis.com') ||
    url.includes('jamendo.com') ||
    url.includes('deezer.com') ||
    url.includes('cloudinary.com') ||
    url.includes('fonts.googleapis.com') ||
    url.includes('fonts.gstatic.com') ||
    url.includes('gstatic.com/firebasejs')
  ) {
    return; // Laisser passer sans cache
  }

  e.respondWith(
    caches.match(e.request).then(cached => {
      // Retourner le cache si disponible
      if (cached) return cached;

      // Sinon fetch depuis le réseau
      return fetch(e.request)
        .then(response => {
          // Mettre en cache seulement les réponses valides
          if (
            response &&
            response.status === 200 &&
            response.type === 'basic'
          ) {
            const clone = response.clone();
            caches.open(CACHE_NAME).then(cache => {
              cache.put(e.request, clone);
            });
          }
          return response;
        })
        .catch(() => {
          // Hors ligne → retourner index.html
          if (e.request.destination === 'document') {
            return caches.match('./index.html');
          }
        });
    })
  );
});

// ── MESSAGE ──
self.addEventListener('message', e => {
  if (e.data && e.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});
