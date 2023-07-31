#!/bin/bash
export CHROMA_SERVER_HTTP_PORT=${CHROMA_SERVER_HTTP_PORT:-8000}
export CHROMA_SERVER_LOG_CONFIG=${CHROMA_SERVER_LOG_CONFIG:-log_config.yaml}
export CHROMA_SERVER_HOST=${CHROMA_SERVER_HOST:-"0.0.0.0"}
. /chroma/venv/bin/activate
uvicorn chromadb.app:app --workers 1 --host ${CHROMA_SERVER_HOST} --port ${CHROMA_SERVER_HTTP_PORT} --proxy-headers --log-config ${CHROMA_SERVER_LOG_CONFIG}
