#!/usr/bin/env bash

# kill previous instances
pid_to_kill=$(ps | grep 'shared.php' | grep -v grep | cut -d ' ' -f 1)
if [[ -n $pid_to_kill ]]; then
    kill -9 $pid_to_kill
fi

./setup_sql.sh

# start websocket
./shared.php &

# start server
php -S 0.0.0.0:8080
