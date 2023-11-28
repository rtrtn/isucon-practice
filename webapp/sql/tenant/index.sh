#!/bin/sh

set -ex

for i in `seq 1 100`
do
  sqlite3 "$i.db" "CREATE INDEX tenant_created_idx ON competition(tenant_id, created_at);"
  sqlite3 "$i.db" "CREATE INDEX tenant_idx ON player(tenant_id);"
  sqlite3 "$i.db" "CREATE INDEX tenant_competition_row_idx ON player_score(tenant_id, competition_id, row_num);"
done
