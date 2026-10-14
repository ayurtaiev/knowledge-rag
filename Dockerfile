FROM python:3.13-slim

LABEL maintainer="Oleksandr Yurtaiev <ayurtaiev@gmail.com>"
LABEL description="Local RAG System for Claude Code — Hybrid search + Cross-encoder Reranking + 13 MCP Tools + 20 Format Parsers"
LABEL org.opencontainers.image.source="https://github.com/ayurtaiev/knowledge-rag"

WORKDIR /app

COPY pyproject.toml requirements.txt ./
COPY mcp_server/ ./mcp_server/
COPY presets/ ./presets/
COPY config.example.yaml LICENSE README.md ./

RUN pip install --no-cache-dir -r requirements.txt ".[server]"

# Pre-download embedding + reranker models into /app/models_cache (matches config.models_cache_dir)
RUN python -c "from fastembed import TextEmbedding; TextEmbedding('BAAI/bge-small-en-v1.5', cache_dir='/app/models_cache')" && \
    python -c "from fastembed.rerank.cross_encoder import TextCrossEncoder; TextCrossEncoder('Xenova/ms-marco-MiniLM-L-6-v2', cache_dir='/app/models_cache')"

# Default container config: streamable-http on 0.0.0.0:8179
RUN sed -e 's/transport: "stdio"/transport: "streamable-http"/' \
        -e 's/host: "127.0.0.1"/host: "0.0.0.0"/' \
        config.example.yaml > config.yaml

VOLUME ["/app/documents", "/app/data"]

EXPOSE 8179

ENTRYPOINT ["python", "-m", "mcp_server.server"]
