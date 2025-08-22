venv:
	python -m venv .venv
install: venv
	. .venv/bin/activate && pip install -r requirements.txt -r requirements-dev.txt && pre-commit install
lint:
	ruff check . && black --check .
test:
	pytest -q
