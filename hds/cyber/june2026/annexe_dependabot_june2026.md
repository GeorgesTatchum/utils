# Annexe - Traçabilité et triage SCA Dependabot juin 2026 (Item 6 du rapport)

Pièce probante générée depuis les exports Dependabot de `sources/` (4 repos oneorthomedical). 177 CVE distinctes (20 portée runtime, 157 portée build/dev) + 17 alertes sans CVE. Aucune en KEV.

Portée déterminée par le flag `dev` des package-lock.json (planners) : **runtime** = livré au navigateur de production (exposition internet, applicable) ; **build** = chaîne de build (exposition hors ligne). Repo one-platform non disponible localement : portée par heuristique de nature du paquet, à confirmer.

## Portée runtime (applicables - évaluées en Item 6 du rapport)

| CVE | Package(s) | Sévérité | Repos |
|-----|-----------|----------|-------|
| CVE-2025-66412 | @angular/compiler | high | plannerHip3D |
| CVE-2026-22610 | @angular/compiler, @angular/core | high | plannerHip3D |
| CVE-2026-27970 | @angular/core | high | plannerHip3D |
| CVE-2026-32635 | @angular/compiler, @angular/core | high | plannerHip3D |
| CVE-2026-40897 | mathjs | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-41139 | mathjs | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-47759 | tinymce | high | one-platform |
| CVE-2026-47761 | tinymce | high | one-platform |
| CVE-2026-47762 | tinymce | high | one-platform |
| CVE-2026-4800 | lodash | high | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2026-50170 | @angular/common | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-50171 | @angular/common | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-54266 | @angular/common | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-54267 | @angular/core | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-54268 | @angular/common | high | plannerHip3D, plannerKneeMadison |
| CVE-2021-4231 | @angular/core | medium | plannerHip3D |
| CVE-2026-2950 | lodash | medium | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2026-50557 | @angular/compiler, @angular/core | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-52725 | @angular/core | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-54265 | @angular/compiler | medium | plannerHip3D, plannerKneeMadison |

## Portée build/dev (hors ligne - lot P4)

| CVE | Package(s) | Sévérité | Repos |
|-----|-----------|----------|-------|
| CVE-2026-27699 | basic-ftp | critical | plannerHip3D |
| CVE-2026-33937 | handlebars | critical | plannerHip3D, plannerKneeMadison |
| CVE-2026-41242 | protobufjs | critical | plannerHip3D |
| CVE-2026-9277 | shell-quote | critical | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2026-12143 | form-data | high | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2026-12151 | undici | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-1526 | undici | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-1528 | undici | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-2229 | undici | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-23745 | tar | high | plannerHip3D |
| CVE-2026-23950 | tar | high | plannerHip3D |
| CVE-2026-24842 | tar | high | plannerHip3D |
| CVE-2026-25536 | @modelcontextprotocol/sdk | high | plannerHip3D |
| CVE-2026-25547 | @isaacs/brace-expansion | high | plannerKneeMadison |
| CVE-2026-25639 | axios | high | plannerKneeMadison |
| CVE-2026-26280 | systeminformation | high | plannerKneeMadison |
| CVE-2026-26318 | systeminformation | high | plannerKneeMadison |
| CVE-2026-26960 | tar | high | plannerHip3D |
| CVE-2026-26996 | minimatch | high | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2026-27606 | rollup | high | plannerHip3D |
| CVE-2026-27903 | minimatch | high | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2026-27904 | minimatch | high | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2026-29045 | hono | high | plannerHip3D |
| CVE-2026-29063 | immutable | high | plannerHip3D |
| CVE-2026-29074 | svgo | high | one-platform |
| CVE-2026-29087 | @hono/node-server | high | plannerHip3D |
| CVE-2026-29786 | tar | high | plannerHip3D |
| CVE-2026-31802 | tar | high | plannerHip3D |
| CVE-2026-32141 | flatted | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-33151 | socket.io-parser | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-33228 | flatted | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-33671 | picomatch | high | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2026-33891 | node-forge | high | one-platform, plannerHip3D |
| CVE-2026-33894 | node-forge | high | one-platform, plannerHip3D |
| CVE-2026-33895 | node-forge | high | one-platform, plannerHip3D |
| CVE-2026-33896 | node-forge | high | one-platform, plannerHip3D |
| CVE-2026-33938 | handlebars | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-33939 | handlebars | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-33940 | handlebars | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-33941 | handlebars | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-39363 | vite | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-39364 | vite | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-41324 | basic-ftp | high | plannerHip3D |
| CVE-2026-42033 | axios | high | plannerKneeMadison |
| CVE-2026-42035 | axios | high | plannerKneeMadison |
| CVE-2026-42043 | axios | high | plannerKneeMadison |
| CVE-2026-42264 | axios | high | plannerKneeMadison |
| CVE-2026-44240 | basic-ftp | high | plannerHip3D |
| CVE-2026-44289 | protobufjs | high | plannerHip3D |
| CVE-2026-44290 | protobufjs | high | plannerHip3D |
| CVE-2026-44291 | protobufjs | high | plannerHip3D |
| CVE-2026-44293 | protobufjs | high | plannerHip3D |
| CVE-2026-44486 | axios | high | plannerKneeMadison |
| CVE-2026-44487 | axios | high | plannerKneeMadison |
| CVE-2026-44488 | axios | high | plannerKneeMadison |
| CVE-2026-44492 | axios | high | plannerKneeMadison |
| CVE-2026-44494 | axios | high | plannerKneeMadison |
| CVE-2026-44495 | axios | high | plannerKneeMadison |
| CVE-2026-44496 | axios | high | plannerKneeMadison |
| CVE-2026-44705 | tmp | high | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2026-44724 | systeminformation | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-44728 | @babel/plugin-transform-modules-systemjs | high | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2026-48068 | @grpc/grpc-js | high | plannerHip3D |
| CVE-2026-48069 | @grpc/grpc-js | high | plannerHip3D |
| CVE-2026-4867 | path-to-regexp | high | one-platform, plannerHip3D |
| CVE-2026-48712 | protobufjs | high | plannerHip3D |
| CVE-2026-48779 | ws | high | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2026-48815 | sigstore | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-4926 | path-to-regexp | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-53571 | vite | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-54290 | hono | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-55388 | piscina | high | plannerHip3D, plannerKneeMadison |
| CVE-2026-55603 | http-proxy-middleware | high | plannerHip3D |
| CVE-2026-6321 | fast-uri | high | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2026-6322 | fast-uri | high | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2023-44270 | postcss | medium | one-platform |
| CVE-2025-13465 | lodash | medium | plannerKneeMadison |
| CVE-2025-30359 | webpack-dev-server | medium | one-platform |
| CVE-2025-30360 | webpack-dev-server | medium | one-platform |
| CVE-2025-62718 | axios | medium | plannerKneeMadison |
| CVE-2025-69873 | ajv | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-1525 | undici | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-1527 | undici | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-22036 | undici | medium | plannerKneeMadison |
| CVE-2026-2581 | undici | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-2739 | bn.js | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-29085 | hono | medium | plannerHip3D |
| CVE-2026-29086 | hono | medium | plannerHip3D |
| CVE-2026-33532 | yaml | medium | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2026-33672 | picomatch | medium | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2026-33750 | brace-expansion | medium | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2026-33916 | handlebars | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-34043 | serialize-javascript | medium | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2026-39365 | vite | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-39406 | @hono/node-server | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-39407 | hono | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-39408 | hono | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-39409 | hono | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-39410 | hono | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-40175 | axios | medium | plannerKneeMadison |
| CVE-2026-41305 | postcss | medium | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2026-41907 | uuid | medium | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2026-42034 | axios | medium | plannerKneeMadison |
| CVE-2026-42036 | axios | medium | plannerKneeMadison |
| CVE-2026-42037 | axios | medium | plannerKneeMadison |
| CVE-2026-42038 | axios | medium | plannerKneeMadison |
| CVE-2026-42039 | axios | medium | plannerKneeMadison |
| CVE-2026-42041 | axios | medium | plannerKneeMadison |
| CVE-2026-42042 | axios | medium | plannerKneeMadison |
| CVE-2026-42044 | axios | medium | plannerKneeMadison |
| CVE-2026-42338 | ip-address | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-44288 | @protobufjs/utf8, protobufjs | medium | plannerHip3D |
| CVE-2026-44292 | protobufjs | medium | plannerHip3D |
| CVE-2026-44294 | protobufjs | medium | plannerHip3D |
| CVE-2026-44455 | hono | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-44456 | hono | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-44457 | hono | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-44458 | hono | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-44490 | axios | medium | plannerKneeMadison |
| CVE-2026-45149 | brace-expansion | medium | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2026-45736 | ws | medium | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2026-45740 | protobufjs | medium | plannerHip3D |
| CVE-2026-47673 | hono | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-47674 | hono | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-47675 | hono | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-47676 | hono | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-48758 | @sigstore/core | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-48816 | @sigstore/verify | medium | plannerKneeMadison |
| CVE-2026-4923 | path-to-regexp | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-53550 | js-yaml | medium | plannerKneeMadison |
| CVE-2026-53632 | launch-editor, vite | medium | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2026-53655 | tar | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-54269 | protobufjs | medium | plannerHip3D |
| CVE-2026-54285 | @opentelemetry/core | medium | plannerHip3D |
| CVE-2026-54286 | hono | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-54287 | hono | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-54288 | hono | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-54289 | hono | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-55602 | http-proxy-middleware | medium | one-platform, plannerHip3D |
| CVE-2026-56761 | hono | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-6402 | webpack-dev-server | medium | one-platform, plannerHip3D |
| CVE-2026-8723 | qs | medium | one-platform, plannerHip3D, plannerKneeMadison |
| CVE-2026-9595 | webpack-dev-server | medium | one-platform, plannerHip3D |
| CVE-2026-9678 | undici | medium | plannerHip3D, plannerKneeMadison |
| CVE-2026-9679 | undici | medium | plannerHip3D, plannerKneeMadison |
| CVE-2017-16137 | debug | low | plannerHip3D, plannerKneeMadison |
| CVE-2025-14505 | elliptic | low | plannerHip3D, plannerKneeMadison |
| CVE-2025-68157 | webpack | low | plannerHip3D |
| CVE-2025-68458 | webpack | low | plannerHip3D |
| CVE-2026-11525 | undici | low | plannerHip3D, plannerKneeMadison |
| CVE-2026-2391 | qs | low | plannerKneeMadison |
| CVE-2026-24001 | diff | low | plannerHip3D, plannerKneeMadison |
| CVE-2026-3449 | @tootallnate/once | low | plannerHip3D |
| CVE-2026-42040 | axios | low | plannerKneeMadison |
| CVE-2026-44459 | hono | low | plannerHip3D, plannerKneeMadison |
| CVE-2026-49356 | @babel/core | low | one-platform, plannerHip3D, plannerKneeMadison, plannerShoulder3D |
| CVE-2026-6733 | undici | low | plannerHip3D, plannerKneeMadison |

## Alertes sans identifiant CVE (GHSA seul)

| Repo | Package | Sévérité | Portée |
|------|---------|----------|--------|
| one-platform | serialize-javascript | high | build (heur.) |
| plannerHip3D | esbuild | low | build |
| plannerHip3D | follow-redirects | medium | build |
| plannerHip3D | basic-ftp | high | build |
| plannerHip3D | hono | medium | build |
| plannerHip3D | handlebars | low | build |
| plannerHip3D | handlebars | medium | build |
| plannerHip3D | hono | medium | build |
| plannerHip3D | serialize-javascript | high | build |
| plannerHip3D | hono | low | build |
| plannerKneeMadison | esbuild | low | build |
| plannerKneeMadison | follow-redirects | medium | build |
| plannerKneeMadison | hono | medium | build |
| plannerKneeMadison | handlebars | medium | build |
| plannerKneeMadison | handlebars | low | build |
| plannerKneeMadison | serialize-javascript | high | build |
| plannerShoulder3D | esbuild | low | build |
