# nin_guide

A new Flutter project.

## Natur i Norge (NiN) Guide

App for mapping and identifying nature types in Norway.

## Landing Page, Web App & Privacy Policy

The project includes a landing page and privacy policy in the `docs/` directory. Web builds and landing pages are published to the dedicated **`gh-pages`** branch.

GitHub Pages is configured to serve from **`gh-pages` / `/ (root)`**:

- Landing page: `https://geco-nhm.github.io/natur-i-norge/`
- Live Flutter Web app: `https://geco-nhm.github.io/natur-i-norge/app/`
- Frozen NiN 2.3 archive: `https://geco-nhm.github.io/natur-i-norge/v2.3/`

### Build and deploy the web app

The web build and deployment is automated via the Jenkins pipeline on release branches (`main`), or can be run manually:

```bash
# Build & assemble staging payload (without pushing)
./scripts/deploy_web.sh

# Build & push directly to gh-pages branch
./scripts/deploy_web.sh --deploy

# Preview locally before deploying (mirrors GitHub Pages URL paths)
./scripts/preview_web.sh
# open http://localhost:8080/natur-i-norge/app/
```

To publish mobile stores and build web in one go:

```bash
./publish.sh all --deploy
```

### Firebase Storage CORS (required for web photos)

The web app loads observation images from Firebase Storage. Browsers block those
requests unless the storage bucket allows your site's origin.

One-time setup (requires [Google Cloud SDK](https://cloud.google.com/sdk) and access to the `natur-i-norge-guide` project):

```bash
gcloud auth login
gcloud config set project natur-i-norge-guide
chmod +x scripts/configure_storage_cors.sh
./scripts/configure_storage_cors.sh
```

This applies `firebase/storage-cors.json`, allowing GitHub Pages and local preview.
Changes usually take effect within a few minutes.

If you develop with `flutter run -d chrome` on a different port, add that origin to
`firebase/storage-cors.json` and re-run the script.

Also ensure **Firebase Console → Authentication → Settings → Authorized domains**
includes `geco-nhm.github.io` and `localhost`.

## Legacy web (v2.3, for posterity)

1. Copy prod `web/` → [`archive/v2.3-web/web/`](archive/v2.3-web/web/)
2. Publish to GitHub Pages:

```bash
./scripts/sync_legacy_web_to_docs.sh   # copies to docs/v2.3/ with correct paths
./publish.sh web --deploy              # or sync runs automatically if archive exists
```

The landing page links to the **live** app (`docs/app/`) and the **v2.3 archive** (`docs/v2.3/`). Preview the full site layout:

```bash
./scripts/preview_web.sh
# http://localhost:8080/natur-i-norge/  (landing + app + v2.3)
```

See [`archive/v2.3-web/README.md`](archive/v2.3-web/README.md) for details.

## License

The application source code in this repository is released under the [MIT License](LICENSE).

Bundled NiN classification data is provided by [Artsdatabanken](https://artsdatabanken.no). User-submitted observations shared via cloud backup are published under [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
