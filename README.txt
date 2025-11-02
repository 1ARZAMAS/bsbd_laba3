docker compose up --build tests

docker cp ./bench/bench_check_vs_trigger.sql firestation-db:/tmp/bench.sql

docker compose exec db psql -U fireadmin -d firestation -f /tmp/bench.sql \
| grep -E 'INSERT 10k|Execution Time'

для отдельного запуска тестов
docker compose run --rm tests   pg_prove -v -h db -p 5432 -d firestation -U postgres   /tests/pgtap/05_read_allowed_incidents.sql

PGPASSWORD=firepass psql -h localhost -p 5434 -U fireadmin -d firestation -c 'CHECKPOINT;'
