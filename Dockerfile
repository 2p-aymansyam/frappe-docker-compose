FROM frappe/erpnext:v15.95.1

USER root

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    python3-dev \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

USER frappe
WORKDIR /home/frappe/frappe-bench

# Just create the apps.txt dynamically - don't pip install yet
COPY --chown=frappe:frappe ./apps /tmp/apps_copy

RUN for app in /tmp/apps_copy/*; do \
      if [ -d "$app" ] && [ "$app" != "/tmp/apps_copy/frappe" ] && [ "$app" != "/tmp/apps_copy/erpnext" ]; then \
        app_name=$(basename "$app"); \
        printf "%s\n" "$app_name" >> /home/frappe/frappe-bench/sites/apps.txt; \
      fi \
    done && \
    sed -i '/^$/d' /home/frappe/frappe-bench/sites/apps.txt && \
    rm -rf /tmp/apps_copy