.PHONY: lint ci-smoke
lint:
	helm lint charts/chromadb-chart

ci-smoke:
	bash tests/ci_smoke.sh
