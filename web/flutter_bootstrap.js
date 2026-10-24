{{flutter_js}}
{{flutter_build_config}}

// Pas de `serviceWorkerSettings` : le service worker de Flutter est
// déprécié (flutter#156910) et n'offrait pas de mode hors ligne.
// CognicQuest enregistre le sien (register_sw.js → cq_service_worker.js).
_flutter.loader.load();
