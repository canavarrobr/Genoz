// Service worker do Genoz.
//
// 1. Isolamento de origem: acrescenta COOP/COEP às respostas. O núcleo Rust
//    (WebAssembly com threads) precisa de SharedArrayBuffer, que só existe com
//    esses cabeçalhos — e o GitHub Pages não permite configurá-los no servidor.
// 2. Funcionamento offline (PWA): tudo do próprio site fica em cache.
//
// Nada fora do próprio site é tocado: requisições para outros endereços nem
// passam por aqui (e a política de segurança da página as bloqueia).

const CACHE = 'genoz-v1';

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));

function withIsolation(response) {
  if (response.status === 0) return response; // resposta opaca: não pode ser alterada
  const headers = new Headers(response.headers);
  headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
  headers.set('Cross-Origin-Opener-Policy', 'same-origin');
  headers.set('Cross-Origin-Resource-Policy', 'same-origin');
  return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
}

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  if (new URL(request.url).origin !== self.location.origin) return;
  event.respondWith(
    (async () => {
      let response;
      try {
        // Rede primeiro (pega atualizações); cache como reserva (offline).
        response = await fetch(request);
        if (response.ok && response.type === 'basic') {
          const cache = await caches.open(CACHE);
          await cache.put(request, response.clone());
        }
      } catch (error) {
        response = await caches.match(request);
        if (!response) throw error;
      }
      return withIsolation(response);
    })(),
  );
});
