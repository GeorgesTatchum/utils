# Pivot SCA Dependabot - august2026

Généré par `fetch_dependabot_alerts.py` (mode `instantane`). **Instantané des alertes ouvertes au 2026-09-01.** Source pivot de la revue mensuelle : identifiant CVE si assigné, sinon GHSA. Dependency-Track et Snyk ne sont consultés qu'en contrôle de delta (cf. `README_pivot_sca_dependabot.md`).

699 alertes, 272 identifiants pivot distincts.

## Couverture des repos

| Repo | Alertes API | Retenues | Statut |
|------|-------------|----------|--------|
| one-platform | 156 | 78 | ok |
| plannerHip2D | 150 | 144 | ok |
| plannerHip3D | 409 | 259 | ok |
| plannerKneeMadison | 370 | 184 | ok |
| plannerShoulder3D | 42 | 34 | ok |

## Mouvements du 2026-08-01 au 2026-09-01

Alimente le §5 (suivi d'un mois sur l'autre). « Ouvertes en fin de fenêtre » est un état, pas un flux : une alerte apparue avant la fenêtre et non corrigée y compte sans compter dans « apparues ».

| Repo | Apparues | Corrigées | Rejetées | Ouvertes en fin de fenêtre |
|------|----------|-----------|----------|----------------------------|
| one-platform | 12 | 0 | 0 | 78 |
| plannerHip2D | 34 | 0 | 0 | 144 |
| plannerHip3D | 46 | 3 | 0 | 259 |
| plannerKneeMadison | 35 | 0 | 0 | 184 |
| plannerShoulder3D | 28 | 0 | 0 | 34 |
| **Total** | **155** | **3** | **0** | **699** |

Ratio corrections / apparitions sur la fenêtre : 3/155 (2%). Mesure directe de l'évolution de la dette SCA (cf. ticket R2).

## Identifiants pivot par portée

### Portée runtime (16)

| Identifiant | Paquet(s) | Sévérité | Repos | Version corrigée | KEV |
|-------------|-----------|----------|-------|------------------|-----|
| CVE-2026-32635 | @angular/compiler, @angular/core | high | plannerHip3D | 20.3.18 | non |
| CVE-2026-40345 | deepmerge-ts | high | plannerKneeMadison | 8.0.0 | non |
| CVE-2026-47759 | tinymce | high | one-platform | 8.5.1 | non |
| CVE-2026-47761 | tinymce | high | one-platform | 8.5.1 | non |
| CVE-2026-47762 | tinymce | high | one-platform | 8.5.1 | non |
| CVE-2026-50170 | @angular/common | high | plannerHip3D | 20.3.22 | non |
| CVE-2026-50171 | @angular/common | high | plannerHip3D | 20.3.22 | non |
| CVE-2026-54266 | @angular/common | high | plannerHip3D | 20.3.25 | non |
| CVE-2026-54268 | @angular/common | high | plannerHip3D | 20.3.25 | non |
| CVE-2026-67320 | axios | high | one-platform | 1.18.0 | non |
| CVE-2026-68945 | @angular/common | high | plannerHip2D, plannerHip3D, plannerKneeMadison | 20.3.27, 21.2.19 | non |
| CVE-2026-69246 | guzzlehttp/guzzle | high | one-platform | 7.15.2 | non |
| CVE-2026-67314 | axios | medium | one-platform | 1.18.0 | non |
| CVE-2026-67315 | axios | medium | one-platform | 1.18.0 | non |
| CVE-2026-69245 | guzzlehttp/guzzle | medium | one-platform | 7.15.2 | non |
| GHSA-hcpx-6fm6-wx23 | axios | medium | one-platform | 1.18.0 | non |

### Portée build (240)

| Identifiant | Paquet(s) | Sévérité | Repos | Version corrigée | KEV |
|-------------|-----------|----------|-------|------------------|-----|
| CVE-2023-46233 | crypto-js | critical | plannerHip2D | 4.2.0 | non |
| CVE-2026-27699 | basic-ftp | critical | plannerHip3D | 5.2.0 | non |
| CVE-2026-33937 | handlebars | critical | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.7.9 | non |
| CVE-2026-41242 | protobufjs | critical | plannerHip3D | 7.5.5 | non |
| CVE-2026-54466 | websocket-driver | critical | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison | 0.7.5 | non |
| CVE-2026-59873 | tar | critical | plannerHip2D, plannerHip3D | 7.5.19 | non |
| CVE-2026-9277 | shell-quote | critical | one-platform, plannerHip3D, plannerKneeMadison | 1.8.4 | non |
| CVE-2022-25883 | semver | high | plannerHip2D | 6.3.1 | non |
| CVE-2024-37890 | ws | high | plannerHip2D | 8.17.1 | non |
| CVE-2024-4367 | pdfjs-dist | high | plannerHip2D | 4.2.67 | non |
| CVE-2025-66412 | @angular/compiler | high | plannerHip3D | - | non |
| CVE-2025-71329 | image-size | high | plannerHip3D | - | non |
| CVE-2025-71330 | image-size | high | plannerHip3D | - | non |
| CVE-2026-12151 | undici | high | plannerHip2D, plannerHip3D, plannerKneeMadison | 6.27.0, 7.28.0 | non |
| CVE-2026-13149 | brace-expansion | high | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 1.1.16, 2.1.2, 5.0.7 | non |
| CVE-2026-13311 | shell-quote | high | one-platform, plannerHip3D, plannerKneeMadison | 1.9.0 | non |
| CVE-2026-13676 | fast-uri | high | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison | 3.1.3 | non |
| CVE-2026-13697 | undici | high | plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 7.29.0 | non |
| CVE-2026-14257 | brace-expansion | high | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 1.1.17, 2.1.3, 5.0.8 | non |
| CVE-2026-1526 | undici | high | plannerHip3D, plannerKneeMadison | 6.24.0, 7.24.0 | non |
| CVE-2026-1528 | undici | high | plannerHip3D | 6.24.0, 7.24.0 | non |
| CVE-2026-16221 | fast-uri | high | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 3.1.4 | non |
| CVE-2026-18446 | fast-uri | high | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 3.1.5 | non |
| CVE-2026-2229 | undici | high | plannerHip3D, plannerKneeMadison | 6.24.0, 7.24.0 | non |
| CVE-2026-22610 | @angular/compiler, @angular/core | high | plannerHip3D | - | non |
| CVE-2026-23745 | tar | high | plannerHip3D | 7.5.3 | non |
| CVE-2026-23950 | tar | high | plannerHip3D | 7.5.4 | non |
| CVE-2026-24842 | tar | high | plannerHip3D | 7.5.7 | non |
| CVE-2026-25536 | @modelcontextprotocol/sdk | high | plannerHip3D | 1.26.0 | non |
| CVE-2026-25547 | @isaacs/brace-expansion | high | plannerKneeMadison | 5.0.1 | non |
| CVE-2026-25639 | axios | high | plannerKneeMadison | 1.13.5 | non |
| CVE-2026-26280 | systeminformation | high | plannerKneeMadison | 5.30.8 | non |
| CVE-2026-26318 | systeminformation | high | plannerKneeMadison | 5.31.0 | non |
| CVE-2026-26960 | tar | high | plannerHip3D | 7.5.8 | non |
| CVE-2026-26996 | minimatch | high | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison | 10.2.1, 3.1.3, 5.1.7, 6.2.1, 7.4.7, 9.0.6 | non |
| CVE-2026-27606 | rollup | high | plannerHip3D | 4.59.0 | non |
| CVE-2026-27903 | minimatch | high | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison | 10.2.3, 3.1.3, 5.1.8, 6.2.2, 7.4.8, 9.0.7 | non |
| CVE-2026-27904 | minimatch | high | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison | 10.2.3, 3.1.4, 5.1.8, 6.2.2, 7.4.8, 9.0.7 | non |
| CVE-2026-29045 | hono | high | plannerHip3D | 4.12.4 | non |
| CVE-2026-29063 | immutable | high | plannerHip3D | 5.1.5 | non |
| CVE-2026-29074 | svgo | high | one-platform | 2.8.1 | non |
| CVE-2026-29087 | @hono/node-server | high | plannerHip3D | 1.19.10 | non |
| CVE-2026-29786 | tar | high | plannerHip3D | 7.5.10 | non |
| CVE-2026-31802 | tar | high | plannerHip3D | 7.5.11 | non |
| CVE-2026-32141 | flatted | high | plannerHip2D, plannerHip3D, plannerKneeMadison | 3.4.0 | non |
| CVE-2026-33151 | socket.io-parser | high | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.2.6 | non |
| CVE-2026-33228 | flatted | high | plannerHip2D, plannerHip3D, plannerKneeMadison | 3.4.2 | non |
| CVE-2026-33671 | picomatch | high | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison | 2.3.2, 4.0.4 | non |
| CVE-2026-33891 | node-forge | high | one-platform, plannerHip3D | 1.4.0 | non |
| CVE-2026-33894 | node-forge | high | one-platform, plannerHip3D | 1.4.0 | non |
| CVE-2026-33895 | node-forge | high | one-platform, plannerHip3D | 1.4.0 | non |
| CVE-2026-33896 | node-forge | high | one-platform, plannerHip3D | 1.4.0 | non |
| CVE-2026-33938 | handlebars | high | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.7.9 | non |
| CVE-2026-33939 | handlebars | high | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.7.9 | non |
| CVE-2026-33940 | handlebars | high | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.7.9 | non |
| CVE-2026-33941 | handlebars | high | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.7.9 | non |
| CVE-2026-39244 | adm-zip | high | plannerKneeMadison | 0.6.0 | non |
| CVE-2026-39363 | vite | high | plannerHip3D | 7.3.2 | non |
| CVE-2026-39364 | vite | high | plannerHip3D | 7.3.2 | non |
| CVE-2026-41324 | basic-ftp | high | plannerHip3D | 5.3.0 | non |
| CVE-2026-42033 | axios | high | plannerKneeMadison | 1.15.1 | non |
| CVE-2026-42035 | axios | high | plannerKneeMadison | 1.15.1 | non |
| CVE-2026-42043 | axios | high | plannerKneeMadison | 1.15.1 | non |
| CVE-2026-42264 | axios | high | plannerKneeMadison | 1.15.2 | non |
| CVE-2026-44240 | basic-ftp | high | plannerHip3D | 5.3.1 | non |
| CVE-2026-44289 | protobufjs | high | plannerHip3D | 7.5.6 | non |
| CVE-2026-44290 | protobufjs | high | plannerHip3D | 7.5.6 | non |
| CVE-2026-44291 | protobufjs | high | plannerHip3D | 7.5.6 | non |
| CVE-2026-44293 | protobufjs | high | plannerHip3D | 7.5.6 | non |
| CVE-2026-44486 | axios | high | plannerKneeMadison | 1.16.0 | non |
| CVE-2026-44487 | axios | high | plannerKneeMadison | 1.16.0 | non |
| CVE-2026-44488 | axios | high | plannerKneeMadison | 1.16.0 | non |
| CVE-2026-44494 | axios | high | plannerKneeMadison | 1.16.0 | non |
| CVE-2026-44495 | axios | high | plannerKneeMadison | 1.15.2 | non |
| CVE-2026-44496 | axios | high | plannerKneeMadison | 1.16.0 | non |
| CVE-2026-44705 | tmp | high | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison | 0.2.6 | non |
| CVE-2026-44724 | systeminformation | high | plannerHip3D, plannerKneeMadison | 5.31.6 | non |
| CVE-2026-44728 | @babel/plugin-transform-modules-systemjs | high | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison | 7.29.4 | non |
| CVE-2026-45623 | postcss | high | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison | 8.5.12 | non |
| CVE-2026-4800 | lodash | high | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison | 4.18.0 | non |
| CVE-2026-48068 | @grpc/grpc-js | high | plannerHip3D | 1.14.4, 1.9.16 | non |
| CVE-2026-48069 | @grpc/grpc-js | high | plannerHip3D | 1.14.4, 1.9.16 | non |
| CVE-2026-4867 | path-to-regexp | high | one-platform, plannerHip3D | 0.1.13 | non |
| CVE-2026-48712 | protobufjs | high | plannerHip3D | 7.6.1 | non |
| CVE-2026-48779 | ws | high | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison | 7.5.11, 8.21.0 | non |
| CVE-2026-48815 | sigstore | high | plannerHip3D | 4.1.1 | non |
| CVE-2026-4926 | path-to-regexp | high | plannerHip2D, plannerHip3D, plannerKneeMadison | 8.4.0 | non |
| CVE-2026-50289 | systeminformation | high | plannerHip3D, plannerKneeMadison | 5.31.7 | non |
| CVE-2026-53571 | vite | high | plannerHip3D | 7.3.5 | non |
| CVE-2026-54290 | hono | high | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.25 | non |
| CVE-2026-55388 | piscina | high | plannerHip3D | 5.2.0 | non |
| CVE-2026-55603 | http-proxy-middleware | high | plannerHip3D | 3.0.7 | non |
| CVE-2026-56876 | extract-zip | high | plannerHip3D, plannerKneeMadison | - | non |
| CVE-2026-59725 | engine.io | high | plannerHip2D, plannerHip3D, plannerKneeMadison | 6.6.7 | non |
| CVE-2026-59869 | js-yaml | high | plannerHip2D, plannerHip3D, plannerKneeMadison | 3.15.0, 4.3.0 | non |
| CVE-2026-59874 | tar | high | plannerHip2D, plannerHip3D | 7.5.18 | non |
| CVE-2026-59879 | immutable | high | plannerHip2D, plannerHip3D, plannerKneeMadison | 5.1.8 | non |
| CVE-2026-59880 | immutable | high | plannerHip2D, plannerHip3D, plannerKneeMadison | 5.1.8 | non |
| CVE-2026-6321 | fast-uri | high | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison | 3.1.1 | non |
| CVE-2026-6322 | fast-uri | high | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison | 3.1.2 | non |
| CVE-2026-67213 | nanoid | high | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 3.3.18 | non |
| CVE-2026-67214 | nanoid | high | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 3.3.16 | non |
| CVE-2026-6734 | undici | high | plannerHip2D | 7.28.0 | non |
| CVE-2026-69152 | brace-expansion | high | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 1.1.18, 2.1.4, 5.0.9 | non |
| CVE-2026-69185 | socket.io-parser | high | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.2.7 | non |
| CVE-2026-69192 | ip-address | high | plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 10.3.1 | non |
| CVE-2026-73566 | tar | high | plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 7.5.21 | non |
| CVE-2026-73646 | postcss | high | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 8.5.18 | non |
| CVE-2026-73650 | svgo | high | one-platform | 2.8.3 | non |
| CVE-2026-9496 | pacote | high | plannerHip3D | 21.5.1 | non |
| CVE-2026-9697 | undici | high | plannerHip2D | 7.28.0 | non |
| GHSA-5c6j-r48x-rmvq | serialize-javascript | high | one-platform, plannerHip3D, plannerKneeMadison | 7.0.3 | non |
| GHSA-5p4m-2wfm-xmqj | js-yaml | high | plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 3.15.1, 4.3.1 | non |
| GHSA-6v7q-wjvx-w8wg | basic-ftp | high | plannerHip3D | 5.2.2 | non |
| CVE-2021-4231 | @angular/core | medium | plannerHip3D | 10.2.5 | non |
| CVE-2023-26159 | follow-redirects | medium | plannerHip2D | 1.15.4 | non |
| CVE-2023-31125 | engine.io | medium | plannerHip2D | 6.4.2 | non |
| CVE-2023-32695 | socket.io-parser | medium | plannerHip2D | 4.2.3 | non |
| CVE-2023-44270 | postcss | medium | one-platform | 8.4.31 | non |
| CVE-2024-28849 | follow-redirects | medium | plannerHip2D | 1.15.6 | non |
| CVE-2024-38355 | socket.io | medium | plannerHip2D | 4.6.2 | non |
| CVE-2025-13465 | lodash | medium | plannerHip2D, plannerKneeMadison | 4.17.23 | non |
| CVE-2025-30359 | webpack-dev-server | medium | one-platform | 5.2.1 | non |
| CVE-2025-30360 | webpack-dev-server | medium | one-platform | 5.2.1 | non |
| CVE-2025-62718 | axios | medium | plannerKneeMadison | 1.15.0 | non |
| CVE-2025-69873 | ajv | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 8.18.0 | non |
| CVE-2026-14620 | webpack-dev-server | medium | one-platform, plannerHip3D | 5.2.6 | non |
| CVE-2026-14631 | webpack-dev-server | medium | one-platform, plannerHip3D | 5.2.6 | non |
| CVE-2026-14643 | undici | medium | plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 7.29.0 | non |
| CVE-2026-15157 | undici | medium | plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 6.28.0, 7.29.0 | non |
| CVE-2026-1525 | undici | medium | plannerHip3D, plannerKneeMadison | 6.24.0, 7.24.0 | non |
| CVE-2026-1527 | undici | medium | plannerHip3D, plannerKneeMadison | 6.24.0, 7.24.0 | non |
| CVE-2026-16728 | undici | medium | plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 6.28.0, 7.29.0 | non |
| CVE-2026-16729 | undici | medium | plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 6.28.0, 7.29.0 | non |
| CVE-2026-22036 | undici | medium | plannerKneeMadison | 6.23.0 | non |
| CVE-2026-2581 | undici | medium | plannerHip3D | 7.24.0 | non |
| CVE-2026-2739 | bn.js | medium | plannerHip3D, plannerKneeMadison | 4.12.3, 5.2.3 | non |
| CVE-2026-29085 | hono | medium | plannerHip3D | 4.12.4 | non |
| CVE-2026-29086 | hono | medium | plannerHip3D | 4.12.4 | non |
| CVE-2026-2950 | lodash | medium | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison | 4.18.0 | non |
| CVE-2026-33532 | yaml | medium | one-platform, plannerHip3D, plannerKneeMadison | 1.10.3, 2.8.3 | non |
| CVE-2026-33672 | picomatch | medium | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison | 2.3.2, 4.0.4 | non |
| CVE-2026-33750 | brace-expansion | medium | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison | 1.1.13, 2.0.3, 5.0.5 | non |
| CVE-2026-33916 | handlebars | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.7.9 | non |
| CVE-2026-34043 | serialize-javascript | medium | one-platform, plannerHip3D, plannerKneeMadison | 7.0.5 | non |
| CVE-2026-39365 | vite | medium | plannerHip3D | 7.3.2 | non |
| CVE-2026-39406 | @hono/node-server | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 1.19.13 | non |
| CVE-2026-39407 | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.12 | non |
| CVE-2026-39408 | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.12 | non |
| CVE-2026-39409 | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.12 | non |
| CVE-2026-39410 | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.12 | non |
| CVE-2026-40175 | axios | medium | plannerKneeMadison | 1.15.0 | non |
| CVE-2026-41305 | postcss | medium | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison | 8.5.10 | non |
| CVE-2026-41907 | uuid | medium | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison | 11.1.1, 13.0.1 | non |
| CVE-2026-42034 | axios | medium | plannerKneeMadison | 1.15.1 | non |
| CVE-2026-42036 | axios | medium | plannerKneeMadison | 1.15.1 | non |
| CVE-2026-42037 | axios | medium | plannerKneeMadison | 1.15.1 | non |
| CVE-2026-42038 | axios | medium | plannerKneeMadison | 1.15.1 | non |
| CVE-2026-42039 | axios | medium | plannerKneeMadison | 1.15.1 | non |
| CVE-2026-42041 | axios | medium | plannerKneeMadison | 1.15.1 | non |
| CVE-2026-42042 | axios | medium | plannerKneeMadison | 1.15.1 | non |
| CVE-2026-42044 | axios | medium | plannerKneeMadison | 1.15.2 | non |
| CVE-2026-42338 | ip-address | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 10.1.1 | non |
| CVE-2026-44288 | @protobufjs/utf8, protobufjs | medium | plannerHip3D | 1.1.1, 7.5.6 | non |
| CVE-2026-44292 | protobufjs | medium | plannerHip3D | 7.5.6 | non |
| CVE-2026-44294 | protobufjs | medium | plannerHip3D | 7.5.6 | non |
| CVE-2026-44455 | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.16 | non |
| CVE-2026-44456 | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.16 | non |
| CVE-2026-44457 | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.18 | non |
| CVE-2026-44458 | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.18 | non |
| CVE-2026-44490 | axios | medium | plannerKneeMadison | 1.16.0 | non |
| CVE-2026-45149 | brace-expansion | medium | one-platform, plannerHip3D | 5.0.6 | non |
| CVE-2026-45736 | ws | medium | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison | 8.20.1 | non |
| CVE-2026-45740 | protobufjs | medium | plannerHip3D | 7.5.8 | non |
| CVE-2026-47673 | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.21 | non |
| CVE-2026-47674 | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.21 | non |
| CVE-2026-47675 | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.21 | non |
| CVE-2026-47676 | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.21 | non |
| CVE-2026-48758 | @sigstore/core | medium | plannerHip3D | 3.2.1 | non |
| CVE-2026-4923 | path-to-regexp | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 8.4.0 | non |
| CVE-2026-5078 | morgan | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 1.11.0 | non |
| CVE-2026-53550 | js-yaml | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 3.15.0, 4.2.0 | non |
| CVE-2026-53632 | launch-editor, vite | medium | one-platform, plannerHip3D | 2.14.1, 7.3.5 | non |
| CVE-2026-53655 | tar | medium | plannerHip3D | 7.5.16 | non |
| CVE-2026-54269 | protobufjs | medium | plannerHip3D | 7.6.3 | non |
| CVE-2026-54272 | ip-address | medium | plannerHip2D, plannerKneeMadison, plannerShoulder3D | 10.2.1 | non |
| CVE-2026-54285 | @opentelemetry/core | medium | plannerHip3D | 2.8.0 | non |
| CVE-2026-54286 | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.25 | non |
| CVE-2026-54287 | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.25 | non |
| CVE-2026-54288 | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.25 | non |
| CVE-2026-54289 | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.25 | non |
| CVE-2026-54490 | websocket-driver | medium | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison | 0.7.5 | non |
| CVE-2026-55602 | http-proxy-middleware | medium | one-platform, plannerHip3D | 2.0.10, 3.0.6 | non |
| CVE-2026-56761 | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.14 | non |
| CVE-2026-59871 | tar | medium | plannerHip2D, plannerHip3D | 7.5.18 | non |
| CVE-2026-59875 | tar | medium | plannerHip3D | 7.5.17 | non |
| CVE-2026-59895 | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.27 | non |
| CVE-2026-59896 | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.27 | non |
| CVE-2026-59897 | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.27 | non |
| CVE-2026-6402 | webpack-dev-server | medium | one-platform, plannerHip3D | 5.2.4 | non |
| CVE-2026-67550 | re2 | medium | plannerHip3D | 1.25.2 | non |
| CVE-2026-68499 | re2 | medium | plannerHip3D | 1.25.2 | non |
| CVE-2026-69153 | postcss | medium | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 8.5.23 | non |
| CVE-2026-69198 | ip-address | medium | plannerHip2D, plannerKneeMadison, plannerShoulder3D | 10.2.2 | non |
| CVE-2026-69207 | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 4.12.34 | non |
| CVE-2026-71430 | re2 | medium | plannerHip3D | 1.25.1 | non |
| CVE-2026-71498 | re2 | medium | plannerHip3D | 1.26.1 | non |
| CVE-2026-71848 | hono | medium | plannerHip2D, plannerKneeMadison, plannerShoulder3D | 4.12.34 | non |
| CVE-2026-71850 | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 4.12.34 | non |
| CVE-2026-8723 | qs | medium | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison | 6.15.2 | non |
| CVE-2026-9595 | webpack-dev-server | medium | one-platform, plannerHip3D | 5.2.5 | non |
| CVE-2026-9678 | undici | medium | plannerHip2D, plannerHip3D | 7.28.0 | non |
| CVE-2026-9679 | undici | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 6.27.0, 7.28.0 | non |
| GHSA-26pp-8wgv-hjvm | hono | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.12 | non |
| GHSA-7rx3-28cr-v5wh | handlebars | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.7.9 | non |
| GHSA-frvp-7c67-39w9 | @hono/node-server | medium | plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 1.19.15 | non |
| GHSA-r4q5-vmmm-2653 | follow-redirects | medium | plannerHip2D, plannerHip3D, plannerKneeMadison | 1.16.0 | non |
| GHSA-v8w9-8mx6-g223 | hono | medium | plannerHip3D | 4.12.7 | non |
| CVE-2017-16137 | debug | low | plannerHip3D, plannerKneeMadison | 4.3.1 | non |
| CVE-2024-27088 | es5-ext | low | plannerHip2D | 0.10.63 | non |
| CVE-2024-47764 | cookie | low | plannerHip2D | 0.7.0 | non |
| CVE-2025-14505 | elliptic | low | plannerHip3D, plannerKneeMadison | - | non |
| CVE-2025-54798 | tmp | low | plannerHip2D | 0.2.4 | non |
| CVE-2025-5889 | brace-expansion | low | plannerHip2D | 1.1.12, 2.0.2 | non |
| CVE-2025-68157 | webpack | low | plannerHip3D | 5.104.0 | non |
| CVE-2025-68458 | webpack | low | plannerHip3D | 5.104.1 | non |
| CVE-2025-7339 | on-headers | low | plannerHip2D | 1.1.0 | non |
| CVE-2026-11525 | undici | low | plannerHip2D, plannerHip3D, plannerKneeMadison | 6.27.0, 7.28.0 | non |
| CVE-2026-12590 | body-parser | low | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison | 1.20.6, 2.3.0 | non |
| CVE-2026-2391 | qs | low | plannerHip2D, plannerKneeMadison | 6.14.2 | non |
| CVE-2026-24001 | diff | low | plannerHip3D, plannerKneeMadison | 4.0.4, 5.2.2, 8.0.3 | non |
| CVE-2026-3449 | @tootallnate/once | low | plannerHip3D | 2.0.1 | non |
| CVE-2026-42040 | axios | low | plannerKneeMadison | 1.15.1 | non |
| CVE-2026-44459 | hono | low | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.12.18 | non |
| CVE-2026-49356 | @babel/core | low | one-platform, plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 7.29.6 | non |
| CVE-2026-6733 | undici | low | plannerHip2D, plannerHip3D, plannerKneeMadison | 6.27.0, 7.28.0 | non |
| CVE-2026-71849 | hono | low | plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 4.12.34 | non |
| GHSA-442j-39wm-28r2 | handlebars | low | plannerHip2D, plannerHip3D, plannerKneeMadison | 4.7.9 | non |
| GHSA-g7r4-m6w7-qqqr | esbuild | low | plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D | 0.28.1 | non |
| GHSA-gq3j-xvxp-8hrf | hono | low | plannerHip3D | 4.11.10 | non |

### Portée mixte / non renseignee (16)

| Identifiant | Paquet(s) | Sévérité | Repos | Version corrigée | KEV |
|-------------|-----------|----------|-------|------------------|-----|
| CVE-2026-12143 | form-data | high | one-platform, plannerHip3D, plannerKneeMadison | 4.0.6 | non |
| CVE-2026-27970 | @angular/core | high | plannerHip3D | 20.3.17 | non |
| CVE-2026-40897 | mathjs | high | plannerHip3D, plannerKneeMadison | 15.2.0 | non |
| CVE-2026-41139 | mathjs | high | plannerHip3D, plannerKneeMadison | 15.2.0 | non |
| CVE-2026-54267 | @angular/core | high | plannerHip3D | 20.3.25 | non |
| CVE-2026-69151 | @angular/compiler, @angular/core | high | plannerHip2D, plannerHip3D, plannerKneeMadison | 20.3.27, 21.2.19 | non |
| CVE-2026-50557 | @angular/compiler, @angular/core | medium | plannerHip3D | 20.3.22 | non |
| CVE-2026-52725 | @angular/core | medium | plannerHip3D | 20.3.22 | non |
| CVE-2026-54265 | @angular/compiler | medium | plannerHip3D | 20.3.25 | non |
| CVE-2026-59877 | protobufjs | medium | plannerHip3D, plannerShoulder3D | 7.6.5 | non |
| CVE-2026-67312 | axios | medium | one-platform, plannerKneeMadison | 1.18.0 | non |
| CVE-2026-67313 | axios | medium | one-platform, plannerKneeMadison | 1.18.0 | non |
| CVE-2026-67316 | axios | medium | one-platform, plannerKneeMadison | 1.18.0 | non |
| CVE-2026-67317 | axios | medium | one-platform, plannerKneeMadison | 1.18.0 | non |
| CVE-2026-67318 | axios | medium | one-platform, plannerKneeMadison | 1.18.0 | non |
| CVE-2026-67319 | axios | medium | one-platform, plannerKneeMadison | 1.18.0 | non |

