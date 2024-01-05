ARG CHROMA_VERSION=0.4.20
FROM ghcr.io/chroma-core/chroma:${CHROMA_VERSION} as base
ARG REBUILD_HNSWLIB=false
COPY ./image/docker_entrypoint.sh /docker_entrypoint.sh
WORKDIR /chroma
RUN find /chroma -mindepth 1 -maxdepth 1 ! \( -name 'chromadb' -o -name 'LICENSE' -o -name 'requirements.txt' \) -exec rm -rf {} \; && \
    groupadd chroma && \
    useradd -g chroma -d /chroma chroma && \
    chown -R chroma:chroma /chroma && \
    apt-get update -qq && apt-get install sqlite3 sudo -y && \
    echo 'chroma ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    apt-get clean && \
    chown -R chroma:chroma /docker_entrypoint.sh
RUN if [ "$REBUILD_HNSWLIB" = "true" ]; then pip install --no-binary :all: --force-reinstall --no-cache-dir --prefix="/install" chroma-hnswlib; fi
EXPOSE 8000
USER chroma

CMD ["/docker_entrypoint.sh"]
