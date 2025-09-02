FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

RUN apt-get update && apt-get install -y curl postgresql-client && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN mkdir -p /app/reports /app/logs /app/tests

CMD ["python", "-m", "pytest", "/app/tests", "-v", \
     "--html=/app/reports/integration-report.html", \
     "--self-contained-html", \
     "--junit-xml=/app/reports/integration-junit.xml"]
