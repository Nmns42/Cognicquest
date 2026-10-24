// Enregistre le service worker hors ligne de CognicQuest.
// Fichier séparé (et non script en ligne) : la CSP interdit le script en
// ligne. Pas en développement local, où un cache servirait du code périmé.
(function () {
  if (!('serviceWorker' in navigator)) return;
  var host = location.hostname;
  if (host === 'localhost' || host === '127.0.0.1') return;
  window.addEventListener('load', function () {
    navigator.serviceWorker
      .register('cq_service_worker.js', { scope: './' })
      .catch(function (error) {
        console.warn('Service worker non enregistré :', error);
      });
  });
})();
