{{flutter_js}}
{{flutter_build_config}}

// Sem service worker do Flutter (o Genoz usa o próprio, genoz_sw.js) e sem
// buscar fontes de reserva na internet: tudo vem do próprio site.
_flutter.loader.load({
  config: {
    fontFallbackBaseUrl: 'assets/fallback-fonts-desativadas/',
  },
});
