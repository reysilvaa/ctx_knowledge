# CTX-Cloud: Self-Hosted Lean-CTX Knowledge Sync with Turso on Vercel

Sistem penyimpanan cloud knowledge mandiri untuk sinkronisasi konteks AI `lean-ctx` antar mesin & repository tanpa berlangganan Pro plan.

## Arsitektur & SoC (Separation of Concerns)
- `src/types.ts`: Domain models & payload interfaces (ISO/Open JSON structure `lean-ctx`).
- `src/db.ts`: LibSQL / Turso connection client singleton & schema auto-migration.
- `src/repository.ts`: Data access layer (CRUD ke Turso SQLite).
- `src/service.ts`: Business logic & validasi payload.
- `src/auth.ts`: Bearer token authentication guard.
- `api/sync.ts`: Vercel serverless function entrypoint (`GET` / `POST`).
- `bin/ctx-sync.sh`: CLI client push/pull dari mesin lokal ke cloud.

## Setup Turso (Gratis 9 GB)
1. Buat database di [Turso](https://turso.tech):
   ```bash
   turso db create ctx-cloud
   turso db show ctx-cloud --url       # TURSO_DATABASE_URL
   turso db tokens create ctx-cloud   # TURSO_AUTH_TOKEN
   ```

2. Konfigurasi Environment Variables di Vercel:
   - `TURSO_DATABASE_URL`: `libsql://ctx-cloud-<org>.turso.io`
   - `TURSO_AUTH_TOKEN`: `<your-turso-token>`
   - `CTX_SECRET_KEY`: `<generate-secret-token>`

## Deploy ke Vercel
```bash
cd ctx-cloud
vercel deploy
```

## Setup Client Lokal
Buat file `~/.config/ctx-cloud.env`:
```bash
CTX_CLOUD_URL="https://your-ctx-app.vercel.app/api/sync"
CTX_CLOUD_TOKEN="<your-secret-token>"
```

Lalu jalankan di repository manapun:
- **Push konteks lokal ke cloud**:
  ```bash
  /home/bms-del053/My-Self/ctx-cloud/bin/ctx-sync.sh push
  ```
- **Pull konteks dari cloud ke mesin lokal**:
  ```bash
  /home/bms-del053/My-Self/ctx-cloud/bin/ctx-sync.sh pull
  ```
- **List repository yang terdaftar di cloud**:
  ```bash
  /home/bms-del053/My-Self/ctx-cloud/bin/ctx-sync.sh list
  ```
