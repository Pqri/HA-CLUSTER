# HA Cluster: Pacemaker/Corosync in Docker + Flask & PostgreSQL (No DRBD First)

Repo ini berisi _production-like_ setup untuk HA Cluster menggunakan **Pacemaker + Corosync** yang berjalan di dalam Docker (container `ha-stack`) serta layanan **Flask App** (image custom) dan **PostgreSQL 16** (image resmi). Tahap ini **tanpa DRBD** terlebih dahulu; replikasi/DRBD dapat ditambahkan belakangan.

> Arsitektur: 2 node (serverA & serverB) + 1 Virtual IP (VIP) yang pindah mengikuti layanan aktif.
> Cluster control-plane berjalan di container `ha-stack` (privileged, host network). PostgreSQL dan Flask diatur sebagai resource Pacemaker via `ocf:heartbeat:docker`.

## Struktur Repo

```
.
├── .github/workflows/
│   └── build-docker.yml          # (opsional) CI untuk build image
├── cluster/
│   ├── compose/
│   │   ├── docker-compose.serverA.yml
│   │   └── docker-compose.serverB.yml
│   ├── corosync/
│   │   └── corosync.conf         # sesuaikan IP/nama node
│   ├── pcs-scripts/
│   │   ├── pcs-bootstrap.sh      # jalankan di container serverA (init cluster)
│   │   ├── pcs-define-resources.sh
│   │   ├── pcs-status.sh
│   │   └── pcs-teardown.sh
│   └── supervisor/
│       ├── supervisord.conf
│       └── pacemaker.conf
├── docker/
│   └── ha-stack/
│       └── Dockerfile            # image Pacemaker+Corosync+pcsd
├── services/
│   ├── flaskapp/
│   │   ├── Dockerfile
│   │   ├── app.py
│   │   ├── requirements.txt
│   │   └── templates/
│   │       └── index.html
│   └── postgres/
│       └── README.md
├── scripts/
│   ├── host-setup.sh             # jalankan di host A & B (persiapan direktori)
│   ├── build-and-copy.sh         # build image dan copy ke serverB
│   ├── db-init.sql               # schema contoh untuk app Flask
│   ├── db-init.sh                # inisialisasi tabel (sekali, di node aktif)
│   ├── switchover.sh             # pindah resource terencana
│   └── fail-stop-start.sh        # simulasi unplanned failover (stop/start corosync/pacemakerd)
├── .env.sample
├── .gitignore
├── LICENSE
└── README.md
```

## Prasyarat

- 2 host Linux (contoh):
  - serverA = `192.168.56.27`
  - serverB = `192.168.56.28`
  - VIP = `192.168.56.30/24`
- Docker Engine + Docker Compose v2 di kedua host.
- Akses SSH antar node untuk `docker save | ssh ... docker load`.
- NIC untuk VIP (contoh `enp0s8`).

## Konfigurasi

1. Salin `.env.sample` menjadi `.env`, lalu sesuaikan nilai:
   - `SERVER_A_IP`, `SERVER_B_IP`, `VIP_ADDR`, `VIP_CIDR`, `VIP_NIC`
   - `PCS_PASSWORD` (password user `hacluster` di container)
   - `TZ`

2. Sesuaikan `cluster/corosync/corosync.conf` untuk IP & nama node (serverA/serverB).

> **Catatan keamanan:** file `cluster/corosync/authkey` **tidak** disertakan. Generate di serverA dan salin manual ke serverB sesuai instruksi di README langkah "Authkey".

## Langkah Cepat (ringkas)

Semua path di bawah ini mengasumsikan repo diposisikan di `/home/pqri/hacluster` di **kedua** host.

### 1) Persiapan host

```bash
cd /home/pqri/hacluster
sudo bash scripts/host-setup.sh
```

### 2) Build image

- Build image cluster di serverA, lalu salin ke serverB:
```bash
docker build -t fiqri/ha-stack:1.3 docker/ha-stack
bash scripts/build-and-copy.sh
```

- Build image Flask app di serverA, lalu salin ke serverB:
```bash
docker build -t flaskapp:latest services/flaskapp
bash scripts/build-and-copy.sh flask
```

### 3) Jalankan container cluster

Di **serverA**:
```bash
docker compose -f cluster/compose/docker-compose.serverA.yml up -d
```

Di **serverB**:
```bash
docker compose -f cluster/compose/docker-compose.serverB.yml up -d
```

### 4) Authkey Corosync

Di **serverA (host)**:
```bash
sudo corosync-keygen
sudo chmod 400 /etc/corosync/authkey
scp /etc/corosync/authkey user@${SERVER_B_IP}:/tmp/
ssh user@${SERVER_B_IP} 'sudo mv /tmp/authkey /etc/corosync/ && sudo chmod 400 /etc/corosync/authkey'
```

### 5) Bootstrap cluster (di container `ha-stack` serverA)

```bash
docker exec -it ha-stack bash -lc 'bash /cluster/pcs-scripts/pcs-bootstrap.sh'
```

### 6) Definisikan resources PG → VIP → Flask (di container serverA)

```bash
docker exec -it ha-stack bash -lc 'bash /cluster/pcs-scripts/pcs-define-resources.sh'
```

### 7) Inisialisasi DB (sekali, di node aktif)

```bash
bash scripts/db-init.sh
```

### 8) Verifikasi & Uji Failover

```bash
docker exec -it ha-stack bash -lc 'bash /cluster/pcs-scripts/pcs-status.sh'
bash scripts/switchover.sh     # planned
bash scripts/fail-stop-start.sh # unplanned
```

## DRBD (Tahap Lanjutan)

Ketika replikasi siap, pindahkan volume PG ke `/mnt/drbd/pgdata` dan tambahkan resource DRBD, Filesystem, serta constraint tambahan (DRBD → FS → PG → app_group).

---

**Catatan:** Repo ini meniru panduan yang sudah Anda susun sebelumnya, namun dipisah rapi per service dan dilengkapi skrip otomatisasi untuk mempercepat provisioning.
