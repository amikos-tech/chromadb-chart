#!/bin/bash
export CHROMA_SERVER_HTTP_PORT=${CHROMA_SERVER_HTTP_PORT:-8000}
export CHROMA_SERVER_LOG_CONFIG=${CHROMA_SERVER_LOG_CONFIG:-/chroma/chromadb/log_config.yml}
export CHROMA_SERVER_HOST=${CHROMA_SERVER_HOST:-"0.0.0.0"}

sudo chown -R chroma:chroma ${PERSIST_DIRECTORY}

uvicorn chromadb.app:app --workers 1 --host ${CHROMA_SERVER_HOST} --port ${CHROMA_SERVER_HTTP_PORT} --proxy-headers --log-config ${CHROMA_SERVER_LOG_CONFIG}
