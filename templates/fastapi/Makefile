venv:
	python -m venv .venv
install: venv
	. .venv/bin/activate && pip install -r requirements.txt -r requirements-dev.txt && pre-commit install
lint:
	ruff check . && black --check .
test:
	pytest -q
run:
	uvicorn app.main:app --reload --port 8000
compose:
	docker compose up --build
