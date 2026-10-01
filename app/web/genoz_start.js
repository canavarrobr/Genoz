// Inicialização do Genoz no navegador.
// Registra o service worker (isolamento de origem + offline) e só então carrega
// o app. Na primeira visita a página recarrega UMA vez, já controlada pelo
// service worker, para receber os cabeçalhos COOP/COEP.

function removeSplashFromWeb() {
  document.getElementById('splash')?.remove();
  document.getElementById('splash-branding')?.remove();
  document.body.style.background = 'transparent';
}

(function () {
  function loadApp() {
    const s = document.createElement('script');
    s.src = 'flutter_bootstrap.js';
    s.async = true;
    document.body.appendChild(s);
  }

  if (window.crossOriginIsolated || !('serviceWorker' in navigator)) {
    loadApp();
    return;
  }

  const tried = sessionStorage.getItem('genoz-isolation-reload');
  navigator.serviceWorker
    .register('genoz_sw.js')
    .then(() => {
      if (tried) {
        // Já recarregou e ainda não está isolado: o app mostra a mensagem de navegador sem suporte.
        loadApp();
        return;
      }
      sessionStorage.setItem('genoz-isolation-reload', '1');
      if (navigator.serviceWorker.controller) {
        window.location.reload();
      } else {
        navigator.serviceWorker.addEventListener('controllerchange', () => window.location.reload());
      }
    })
    .catch(loadApp);
})();
