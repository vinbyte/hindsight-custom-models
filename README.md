# Hindsight Custom Models

Konfigurasi Docker Compose untuk menjalankan [Hindsight](https://github.com/vectorize-io/hindsight) dengan PostgreSQL 17, Timescale extensions, embedding model lokal, dan reranker lokal.

## Fitur

- PostgreSQL 17 dengan `pgvector`, `pgvectorscale`, dan `pg_textsearch`.
- Embedding dan reranker diunduh saat image dibangun, lalu digunakan secara offline saat runtime.
- LLM memakai endpoint OpenAI-compatible, misalnya DeepSeek, OpenRouter, Groq, Ollama, atau LM Studio.
- Data PostgreSQL disimpan di Docker volume `pg_data`.
- HTTP API dan gRPC Hindsight diekspos melalui port yang dapat dikonfigurasi.

## Prasyarat

- Docker Engine dengan Docker Compose v2.
- Akses internet saat image pertama kali dibangun untuk mengunduh base image, dependency, dan model Hugging Face.
- API key untuk provider LLM yang dipilih, kecuali menggunakan LLM lokal.
- CPU dan disk yang cukup untuk PostgreSQL, embedding model, serta reranker.

## Mulai cepat

1. Salin konfigurasi environment:

   ```bash
   cp .env.example .env
   ```

2. Edit `.env`, terutama konfigurasi LLM:

   ```dotenv
   HINDSIGHT_API_LLM_BASE_URL=https://api.deepseek.com
   HINDSIGHT_API_LLM_API_KEY=sk-your-api-key
   HINDSIGHT_API_LLM_MODEL=deepseek-v4-flash
   ```

3. Build dan jalankan seluruh service:

   ```bash
   docker compose up -d --build
   ```

   Build pertama dapat berlangsung cukup lama karena dependency Python dan model lokal diunduh ke dalam image.

4. Periksa status service:

   ```bash
   docker compose ps
   docker compose logs -f hindsight
   ```

Setelah container siap, Hindsight tersedia di:

- HTTP: `http://localhost:8888`
- gRPC: `localhost:9999`

## Service

| Service | Peran |
| --- | --- |
| `db` | PostgreSQL 17 dengan extension vector dan text search |
| `timescale-init` | Menyiapkan database dan extension Timescale saat startup |
| `hindsight` | Menjalankan Hindsight API dengan model lokal |

`hindsight` menunggu `db` sehat dan `timescale-init` selesai sebelum dijalankan.

## Konfigurasi penting

| Variable | Default | Keterangan |
| --- | --- | --- |
| `HINDSIGHT_DB_USER` | `hindsight_user` | User PostgreSQL |
| `HINDSIGHT_DB_PASSWORD` | — | Password PostgreSQL; ganti sebelum deployment |
| `HINDSIGHT_DB_NAME` | `hindsight_db` | Nama database |
| `HINDSIGHT_DB_PORT` | `5438` | Port PostgreSQL pada host |
| `HINDSIGHT_HTTP_PORT` | `8888` | Port HTTP pada host |
| `HINDSIGHT_GRPC_PORT` | `9999` | Port gRPC pada host |
| `HINDSIGHT_API_LLM_BASE_URL` | — | Base URL API LLM OpenAI-compatible |
| `HINDSIGHT_API_LLM_API_KEY` | — | API key LLM |
| `HINDSIGHT_API_LLM_MODEL` | `deepseek-v4-flash` | Nama model LLM |
| `HINDSIGHT_EMBEDDING_MODEL` | `microsoft/harrier-oss-v1-0.6b` | Model embedding lokal |
| `HINDSIGHT_RERANKER_MODEL` | `cross-encoder/mmarco-mMiniLMv2-L12-H384-v1` | Model reranker lokal |
| `HINDSIGHT_CPU_LIMIT` | `4.0` | Batas CPU container Hindsight |
| `HINDSIGHT_OMP_NUM_THREADS` | `4` | Jumlah thread model lokal |

Jika password database mengandung karakter khusus seperti `#`, `@`, `:`, atau `/`, URL-encode karakter tersebut ketika mengisi `HINDSIGHT_DATABASE_URL`. Contoh tersedia di `.env.example`.

## Mengganti model lokal

Atur model di `.env`, kemudian build ulang image:

```dotenv
HINDSIGHT_EMBEDDING_MODEL=BAAI/bge-small-en-v1.5
HINDSIGHT_RERANKER_MODEL=BAAI/bge-reranker-v2-m3
```

```bash
docker compose build --no-cache hindsight
docker compose up -d
```

Model harus dapat diunduh saat proses build. Container Hindsight dikonfigurasi dengan `HF_HUB_OFFLINE=1` dan `TRANSFORMERS_OFFLINE=1`, sehingga model yang tidak tersedia di image akan menyebabkan startup gagal.

## Perintah operasional

```bash
# Melihat status
docker compose ps

# Mengikuti seluruh log
docker compose logs -f

# Restart Hindsight
docker compose restart hindsight

# Menghentikan container tanpa menghapus data
docker compose down
```

Untuk menghapus container sekaligus data PostgreSQL, jalankan perintah berikut dengan hati-hati:

```bash
docker compose down -v
```

## Struktur file

```text
.
├── docker-compose.yaml   # Orkestrasi database, init, dan Hindsight
├── Dockerfile.db         # PostgreSQL 17 + extension Timescale
├── Dockerfile.hindsight  # Hindsight + model lokal
├── .env.example          # Template konfigurasi
└── LICENSE               # MIT License
```

## Lisensi

Proyek ini menggunakan [MIT License](LICENSE).
