# Hindsight Custom Models

Docker Compose configuration for running [Hindsight](https://github.com/vectorize-io/hindsight) with PostgreSQL 17, Timescale extensions, a local embedding model, and a local reranker.

## Features

- PostgreSQL 17 with `pgvector`, `pgvectorscale`, and `pg_textsearch`.
- Embedding and reranker models are downloaded during the image build and used offline at runtime.
- The LLM uses an OpenAI-compatible endpoint such as DeepSeek, OpenRouter, Groq, Ollama, or LM Studio.
- PostgreSQL data is persisted in the Docker volume `pg_data`.
- Hindsight HTTP API and gRPC endpoints are exposed on configurable ports.

## Prerequisites

- Docker Engine with Docker Compose v2.
- Internet access during the initial image build to download the base image, dependencies, and Hugging Face models.
- An API key for the selected LLM provider, unless you use a local LLM.
- Sufficient CPU and disk capacity for PostgreSQL, the embedding model, and the reranker.

## Quick start

1. Copy the environment configuration:

   ```bash
   cp .env.example .env
   ```

2. Edit `.env`, especially the LLM configuration:

   ```dotenv
   HINDSIGHT_API_LLM_BASE_URL=https://api.deepseek.com
   HINDSIGHT_API_LLM_API_KEY=sk-your-api-key
   HINDSIGHT_API_LLM_MODEL=deepseek-v4-flash
   ```

3. Build and start all services:

   ```bash
   docker compose up -d --build
   ```

   The first build may take some time because Python dependencies and local models are downloaded into the image.

4. Check the service status:

   ```bash
   docker compose ps
   docker compose logs -f hindsight
   ```

Once the containers are ready, Hindsight is available at:

- HTTP: `http://localhost:8888`
- gRPC: `localhost:9999`

## Coding agents

Install the unified integration for all detected coding agents, including
Claude Code, Codex, OpenCode, Antigravity, Cursor, and Copilot:

```bash
npx @vectorize-io/hindsight-coding-agents install all --server self-hosted --api-url https://<HINDSIGHT_API_DOMAIN>
```

Then create `~/.hindsight/coding-agent.json` on each developer machine:

```json
{
  "apiUrl": "https://<HINDSIGHT_API_DOMAIN>",
  "bankId": "hive-mind"
}
```

If REST API authentication is enabled, also add
`"apiToken": "<HINDSIGHT_API_TENANT_API_KEY>"`. The direct remote MCP
token is a separate option; see the detailed integration guide.

Replace the API domain and bank ID as needed. See
[CODING_AGENT_INTEGRATION.md](CODING_AGENT_INTEGRATION.md) for configuration,
path opt-in, migration, and troubleshooting details.

## Service

| Service | Role |
| --- | --- |
| `db` | PostgreSQL 17 with vector and text search extensions |
| `timescale-init` | Prepares the database and Timescale extensions at startup |
| `hindsight` | Runs the Hindsight API with local models |

The `hindsight` service waits for `db` to become healthy and for `timescale-init` to complete before starting.

`timescale-init` is safe to run again: the script waits for PostgreSQL, creates the database only if it does not exist, and uses `CREATE EXTENSION IF NOT EXISTS` for each extension.

## Key configuration

| Variable | Default | Description |
| --- | --- | --- |
| `HINDSIGHT_DB_USER` | `hindsight_user` | PostgreSQL user |
| `HINDSIGHT_DB_PASSWORD` | — | PostgreSQL password; change before deployment |
| `HINDSIGHT_DB_NAME` | `hindsight_db` | Database name |
| `HINDSIGHT_DB_PORT` | `5438` | PostgreSQL port on the host |
| `HINDSIGHT_HTTP_PORT` | `8888` | HTTP port on the host |
| `HINDSIGHT_GRPC_PORT` | `9999` | gRPC port on the host |
| `HINDSIGHT_API_LLM_BASE_URL` | — | OpenAI-compatible LLM API base URL |
| `HINDSIGHT_API_LLM_API_KEY` | — | LLM API key |
| `HINDSIGHT_API_LLM_MODEL` | `deepseek-v4-flash` | LLM model name |
| `HINDSIGHT_API_TENANT_EXTENSION` | — | Optional REST API authentication extension |
| `HINDSIGHT_API_TENANT_API_KEY` | — | Optional REST API Bearer token for coding-agent hooks |
| `HINDSIGHT_API_MCP_AUTH_TOKEN` | — | Optional Bearer token for direct remote MCP clients |
| `HINDSIGHT_EMBEDDING_MODEL` | `BAAI/bge-m3` | Local embedding model |
| `HINDSIGHT_RERANKER_MODEL` | `cross-encoder/mmarco-mMiniLMv2-L12-H384-v1` | Local reranker model |
| `HINDSIGHT_CPU_LIMIT` | `4.0` | Hindsight container CPU limit |
| `HINDSIGHT_OMP_NUM_THREADS` | `4` | Number of local-model threads |

If the database password contains special characters such as `#`, `@`, `:`, or `/`, URL-encode them when setting `HINDSIGHT_DATABASE_URL`. An example is available in `.env.example`.

## Changing local models

Set the models in `.env`, then rebuild the image:

```dotenv
HINDSIGHT_EMBEDDING_MODEL=BAAI/bge-small-en-v1.5
HINDSIGHT_RERANKER_MODEL=BAAI/bge-reranker-v2-m3
```

```bash
docker compose build --no-cache hindsight
docker compose up -d
```

The models must be downloadable during the build. The Hindsight container is configured with `HF_HUB_OFFLINE=1` and `TRANSFORMERS_OFFLINE=1`, so startup fails if a model is not available in the image.

## Operational commands

```bash
# Show status
docker compose ps

# Follow all logs
docker compose logs -f

# Restart Hindsight
docker compose restart hindsight

# Stop containers without removing data
docker compose down
```

To remove the containers and PostgreSQL data, run the following command with caution:

```bash
docker compose down -v
```

## File structure

```text
.
├── docker-compose.yaml   # Database, initialization, and Hindsight orchestration
├── Dockerfile.db         # PostgreSQL 17 + Timescale extensions
├── Dockerfile.hindsight  # Hindsight + local models
├── .env.example          # Configuration template
└── LICENSE               # MIT License
```

## License

This project is licensed under the [MIT License](LICENSE).
