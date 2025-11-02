FROM postgres:18-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends postgresql-18-pgaudit \
    && apt-get install -y --no-install-recommends postgresql-18-pgtap pgtap \
    && rm -rf /var/lib/apt/lists/*
