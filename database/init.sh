#!/bin/bash
set -e

# Source PostgreSQL environment
source /usr/local/bin/docker-entrypoint.sh

# Wait for PostgreSQL to start
echo "Waiting for PostgreSQL to start..."
until pg_isready -h localhost -U postgres; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 1
done

echo "PostgreSQL is up"

# Run init script
echo "Running initialization script..."
psql -U postgres < /docker-entrypoint-initdb.d/init.sql

echo "Database initialization complete"
