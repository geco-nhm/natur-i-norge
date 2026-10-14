# NiN Guide — v2.3 web (production snapshot)

Static Flutter web build from production, preserved so the old UI can be opened locally without rebuilding from the `v2.3` branch.

| Field | Value |
|-------|--------|
| Source branch | `v2.3` |
| App version (branch tip) | `0.0.41+41` (`naturinorge_guide`) |
| Captured from | Production deployment |
| Captured on | _fill in when you copy files_ |

## Folder layout

Copy **everything** from the production `web/` output into this folder (either directly here, or into a `web/` subfolder — both work):

```
archive/v2.3-web/
├── README.md          ← this file
├── MANIFEST.json      ← optional metadata (edit after copy)
├── index.html         ← prod files can live here …
├── main.dart.js
│   … or under web/:
└── web/
    ├── index.html
    ├── main.dart.js
    ├── flutter.js          (if present)
    ├── assets/
    ├── icons/
    ├── splash/
    ├── sql-wasm.js
    └── …
```

Quick copy from a local folder named `web`:

```bash
rsync -a --delete /path/to/prod/web/ archive/v2.3-web/
# or: rsync -a --delete /path/to/prod/web/ archive/v2.3-web/web/
```

Or if prod gave you a tarball:

```bash
tar -xf prod-web.tar -C archive/v2.3-web/
# ensure files end up in archive/v2.3-web/web/, not an extra nesting level
```

**Sanity check** after copying:

```bash
test -f archive/v2.3-web/index.html || test -f archive/v2.3-web/web/index.html
test -f archive/v2.3-web/main.dart.js || test -f archive/v2.3-web/web/main.dart.js
```

## Publish on GitHub Pages

After copying files into `web/`:

```bash
./scripts/sync_legacy_web_to_docs.sh
```

This copies (with path fixes) to `docs/v2.3/`. The site landing page at `docs/index.html` links to:

- **Live app:** `/natur-i-norge/app/`
- **This archive:** `/natur-i-norge/v2.3/`

Deploy with the normal web publish flow (`./publish.sh web --deploy`); sync runs automatically when this archive exists.

Preview the full Pages layout (landing + live + legacy):

```bash
./scripts/preview_web.sh
```

Or serve only the raw archive folder:

```bash
./scripts/preview_legacy_web.sh   # http://localhost:8081/
```

## Notes

- `archive/v2.3-web/web/` is the source of truth; `docs/v2.3/` is generated — do not edit `docs/v2.3/` by hand.
- The live app builds into `docs/app/` via `./publish.sh web`.
- Observation photos may still call Firebase Storage; see root `README.md` → Firebase Storage CORS.
- Commit `archive/v2.3-web/web/` and run sync before deploy so `docs/v2.3/` is included in the Pages commit.
