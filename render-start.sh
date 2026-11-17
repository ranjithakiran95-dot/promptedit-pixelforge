#!/bin/sh
set -eu

php artisan optimize:clear
php artisan migrate --force

# Process image generation jobs.
php artisan queue:work database \
    --queue=default \
    --sleep=1 \
    --tries=5 \
    --timeout=45 &

# Run scheduled recovery tasks.
(
    while true; do
        php artisan schedule:run || true
        sleep 60
    done
) &

# Start Laravel on Render's port.
exec php artisan serve \
    --host=0.0.0.0 \
    --port="${PORT:-10000}"
