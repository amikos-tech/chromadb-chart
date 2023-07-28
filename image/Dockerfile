FROM ghcr.io/chroma-core/chroma:0.4.3
COPY ./image/docker_entrypoint.sh /docker_entrypoint.sh
RUN find /chroma -mindepth 1 -maxdepth 1 ! \( -name 'chromadb' -o -name 'LICENSE' -o -name 'requirements.txt' \) -exec rm -rf {} \; && \
    groupadd chroma && \
    useradd -g chroma chroma && \
    chown -R chroma:chroma /chroma
EXPOSE 8000
USER chroma
WORKDIR /chroma
CMD ["/docker_entrypoint.sh"]
