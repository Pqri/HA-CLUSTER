# PostgreSQL Service

- Menggunakan image resmi: `postgres:16`
- Data directory host: `/var/lib/pg-ha` (pastikan kepemilikan `999:999`)
- Dikelola oleh Pacemaker via resource agent `ocf:heartbeat:docker` (lihat skrip di `cluster/pcs-scripts/pcs-define-resources.sh`).

Variabel penting (lihat `.env`):
- `DB_USER`, `DB_PASS`, `DB_NAME`, `DB_PORT`
