FROM ghcr.io/chroma-core/chroma:0.4.3

COPY ./image/docker_entrypoint.sh /docker_entrypoint.sh
RUN find /chroma -mindepth 1 -maxdepth 1 ! \( -name 'chromadb' -o -name 'LICENSE' -o -name 'requirements.txt' \) -exec rm -rf {} \; && \
    groupadd chroma && \
    pip install virtualenv && \
    useradd -g chroma chroma && \
    python -m virtualenv /chroma/venv && \
    . /chroma/venv/bin/activate && \
    pip install --force-reinstall --no-cache-dir -r /chroma/requirements.txt && \
    chown -R chroma:chroma /chroma && \
    apt-get update -qq && apt-get install sqlite3
EXPOSE 8000
USER chroma
WORKDIR /chroma
CMD ["/docker_entrypoint.sh"]
