// Service worker hors ligne de CognicQuest.
//
// `tool/generate_service_worker.dart` remplace VERSION et PRECACHE après
// `flutter build web --no-web-resources-cdn` (CanvasKit servi par l'app,
// donc disponible hors ligne). Sans cette étape (build local), la liste est
// vide et le cache se remplit à l'usage.
//
// Stratégies :
// - navigation : réseau d'abord, sinon index.html en cache (l'app démarre
//   hors ligne, Drift prend le relais pour les données) ;
// - fichiers de l'app (même origine) : cache d'abord, réseau sinon, et mise
//   en cache au passage ;
// - autres origines (Supabase, polices) : jamais interceptées.
'use strict';

const VERSION = '__CQ_VERSION__';
const PRECACHE = /* __CQ_PRECACHE__ */ [];
const CACHE = 'cognicquest-' + VERSION;

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE)
      .then((cache) => cache.addAll(['./', ...PRECACHE]))
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(
        keys
          .filter((key) => key.startsWith('cognicquest-') && key !== CACHE)
          .map((key) => caches.delete(key)),
      ))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request)
        .then((response) => {
          const copy = response.clone();
          caches.open(CACHE).then((cache) => cache.put('./', copy));
          return response;
        })
        .catch(() => caches.match('./')),
    );
    return;
  }

  event.respondWith(
    caches.match(request).then((cached) => {
      if (cached) return cached;
      return fetch(request).then((response) => {
        if (response.ok && response.type === 'basic') {
          const copy = response.clone();
          caches.open(CACHE).then((cache) => cache.put(request, copy));
        }
        return response;
      });
    }),
  );
});
