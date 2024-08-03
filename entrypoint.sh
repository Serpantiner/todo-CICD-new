#!/bin/sh

if [ "$FLASK_ENV" = "development" ]; then
    cp /app/templates/dev_index.html /app/src/templates/index.html
else
    cp /app/templates/prod_index.html /app/src/templates/index.html
fi

exec python src/app.py