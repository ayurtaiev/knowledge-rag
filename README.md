# knowledge-rag

Local Hybrid RAG MCP server (Semantic Search + BM25 + Cross-Encoder Reranking) powered by ChromaDB and FastEmbed ONNX. Runs 100% locally with multi-arch Docker support (`linux/arm64` & `linux/amd64`).

---

## 🚀 Quick Start

### Option 1 — Docker (Recommended, `linux/arm64` & `linux/amd64`)

The Docker image comes with the embedding (`BAAI/bge-small-en-v1.5`) and reranker (`Xenova/ms-marco-MiniLM-L-6-v2`) models pre-downloaded and starts a `streamable-http` server on `0.0.0.0:8179` by default.

```bash
docker pull ghcr.io/ayurtaiev/knowledge-rag:latest

docker run -d --name knowledge-rag \
  -p 8179:8179 \
  -v $(pwd)/documents:/app/documents \
  -v $(pwd)/data:/app/data \
  ghcr.io/ayurtaiev/knowledge-rag:latest
```

**Verify health:**
```bash
curl http://127.0.0.1:8179/health
```

**Build locally (Apple Silicon / ARM64):**
```bash
docker build --platform linux/arm64 -t knowledge-rag:arm64 .
```

---

### Option 2 — Poetry / Git Installation

Install directly from this repository (include `[server]` extra for `streamable-http` / `sse` transports):

```bash
poetry add "git+ssh://git@github.com/ayurtaiev/knowledge-rag.git#master" --extras server
```

Initialize configuration and `documents/` folder:
```bash
poetry run knowledge-rag init
cp config.example.yaml config.yaml
```

Run the server:
```bash
# Streamable HTTP (recommended shared server on http://127.0.0.1:8179/mcp)
poetry run knowledge-rag --transport streamable-http

# SSE (legacy HTTP+SSE on http://127.0.0.1:8179/sse)
poetry run knowledge-rag --transport sse

# Stdio (single-client pipe mode)
poetry run knowledge-rag --transport stdio
```

---

## 🔌 Connecting MCP Clients

### HTTP Mode (`streamable-http` / Docker)
Point your MCP client (`mcp_config.json` / `.cursor/mcp.json`) to the running server:

```json
{
  "mcpServers": {
    "knowledge-rag": {
      "serverUrl": "http://127.0.0.1:8179/mcp"
    }
  }
}
```
*(If using `--transport sse`, set the URL to `http://127.0.0.1:8179/sse`.)*

### Stdio Mode
```json
{
  "mcpServers": {
    "knowledge-rag": {
      "command": "/path/to/.venv/bin/knowledge-rag",
      "env": {
        "KNOWLEDGE_RAG_SINGLE_INSTANCE": "1"
      }
    }
  }
}
```

> **Note:** Do not run multiple `knowledge-rag` writer processes against the same `data_dir` simultaneously. Avoid placing `paths.data_dir` inside cloud-synced folders (iCloud, OneDrive, Dropbox, Google Drive), as file-sync locks can corrupt ChromaDB/SQLite WAL files.

---

## 🛠️ Available MCP Tools (13)

| Tool | Description |
|---|---|
| `search_knowledge` | Hybrid semantic + BM25 search with cross-encoder reranking |
| `get_document` | Retrieve the full content of a specific document by filepath |
| `search_similar` | Find documents semantically similar to a reference document |
| `evaluate_retrieval` | Evaluate search quality (MRR@5, Recall@5, Precision@5) |
| `add_document` | Add and index a new document from raw text |
| `update_document` | Replace content of an existing document and re-index |
| `remove_document` | Remove a document from the index (and optionally delete from disk) |
| `add_from_url` | Fetch content from a URL, convert to Markdown, and index |
| `list_documents` | List all indexed documents (optionally filtered by category) |
| `list_categories` | List all document categories and document counts |
| `get_index_stats` | Get index statistics, model info, and cache hit rate |
| `reindex_documents` | Trigger incremental or full rebuild in the background |
| `get_reindex_status` | Poll progress of a background reindex operation |

---

## ⚙️ Configuration (`config.yaml`)

All settings are optional and fall back to defaults when omitted. To customize a Docker container, mount your own config file via `-v $(pwd)/config.yaml:/app/config.yaml:ro`.

```yaml
paths:
  documents_dir: "./documents"
  data_dir: "./data"
  models_cache_dir: "./models_cache"

models:
  embedding:
    profile: "compact"          # "compact" (bge-small-en-v1.5) | "quality" | "multilingual" | "custom"
    gpu: "auto"                 # "auto" | "true" | "false" | "directml"
  reranker:
    enabled: true
    model: "Xenova/ms-marco-MiniLM-L-6-v2"

search:
  default_results: 5
  max_results: 100

server:
  transport: "streamable-http"  # "stdio" | "sse" | "streamable-http"
  host: "0.0.0.0"               # "127.0.0.1" for local-only, "0.0.0.0" for Docker
  port: 8179
  auth:
    bearer_token: ""            # Set token to require Authorization: Bearer <token>
  rate_limit:
    enabled: false
  metrics:
    enabled: false
    port: 9179
```

Domain presets are available in [`presets/`](presets/):
- [`general.yaml`](presets/general.yaml)
- [`developer.yaml`](presets/developer.yaml)
- [`cybersecurity.yaml`](presets/cybersecurity.yaml)
- [`research.yaml`](presets/research.yaml)
- [`multilingual.yaml`](presets/multilingual.yaml)

---

## 📄 Supported File Formats

`.md`, `.txt`, `.pdf`, `.docx`, `.xlsx`, `.pptx`, `.csv`, `.ipynb`, `.json`, `.hujson`, `.xml`, `.yaml`, `.yml`, `.py`, `.c`, `.h`, `.cpp`, `.js`, `.jsx`, `.ts`, `.tsx`, `.go`, `.rs`, `.kt`, `.cue`, `.proto`, `.rego`, `.sql`, `.sh`, `.jq`, `Dockerfile`, `Makefile`, `Tiltfile` (plus opt-in `.mq4`, `.mqh`).

---

## 📚 Additional Documentation

- [Installation Guide](docs/INSTALLATION.md)
- [API Reference](docs/API.md)
- [Configuration Guide](docs/CONFIGURATION.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

---

## 📜 License

[MIT License](LICENSE)
