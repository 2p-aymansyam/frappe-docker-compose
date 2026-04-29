#!/bin/bash
set -e

echo "Waiting for database..."
while ! mysqladmin ping -h "$DB_HOST" -u root -padmin --silent; do
  sleep 2
done

# 1. Setup Common Site Config for Development
echo "Configuring common_site_config.json..."
bench set-config -g db_host "$DB_HOST"
bench set-config -g redis_cache "redis://$REDIS_CACHE:6379"
bench set-config -g redis_queue "redis://$REDIS_QUEUE:6379"
bench set-config -g redis_socketio "redis://$REDIS_QUEUE:6379"
bench set-config -g socketio_port 9000

# CRITICAL: Enables Python hot-reloading on file save
bench set-config -g developer_mode 1

git config --global --add safe.directory '*'
# 2. Dynamically Link and Install Custom Apps from Windows
shopt -s nullglob
for app_path in /opt/custom_apps/*; do
    # Verify it's a valid app folder by checking for setup files
    if [ -d "$app_path" ] && { [ -f "$app_path/setup.py" ] || [ -f "$app_path/pyproject.toml" ]; }; then
        app_name=$(basename "$app_path")

                # Only get the app if it hasn't been linked into the bench yet
        if [ ! -d "apps/$app_name" ]; then
            echo "Installing $app_name via bench get-app..."
            
            # --soft-link creates a symlink to your Windows mount (enabling hot-reload)
            # --resolve-deps ensures any Python/Node dependencies are handled natively
            bench get-app --resolve-deps --soft-link "$app_path"
        fi
    fi
done
shopt -u nullglob

# 3. Handle Multiple Sites
# Split the SITES_LIST environment variable by comma
IFS=',' read -ra ADDR <<< "$SITES_LIST"

for SITE_NAME in "${ADDR[@]}"; do
    if [ ! -d "sites/$SITE_NAME" ]; then
        echo "Creating new site: $SITE_NAME..."
        bench new-site "$SITE_NAME" \
            --db-host "$DB_HOST" \
            --mariadb-user-host-login-scope '%' \
            --admin-password admin \
            --db-root-username root \
            --db-root-password admin
    fi

    echo "Syncing apps and migrations for $SITE_NAME..."
    # Automatically install any custom apps found in /apps onto this site
    for app_path in apps/*; do
        app_name=$(basename "$app_path")
        # Skip core frappe/erpnext as they are handled by new-site/bench
        if [ "$app_name" != "frappe" ] && [ "$app_name" != "erpnext" ] && [ -d "$app_path" ]; then
            echo "Ensuring $app_name is installed on $SITE_NAME..."
            bench --site "$SITE_NAME" install-app "$app_name" || true
        fi
    done

    bench --site "$SITE_NAME" migrate
    bench --site "$SITE_NAME" clear-cache
done

# 4. Start the Development Server
echo "Generating Procfile..."
rm -f Procfile
cat > Procfile <<EOF
web: bench serve  


socketio: /home/frappe/.nvm/versions/node/v20.19.2/bin/node apps/frappe/socketio.js


watch: bench watch


schedule: bench schedule

worker:  bench worker 1>> logs/worker.log 2>> logs/worker.error.log

EOF


# Remove the Redis lines from the Procfile so Honcho doesn't try to run them
sed -i '/redis/d' Procfile

echo "Starting Multi-tenant Frappe Environment..."
exec bench start
