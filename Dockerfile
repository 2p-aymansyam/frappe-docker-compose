FROM frappe/erpnext:v15.95.1

USER root

# Install system dependencies required for building Python packages
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    python3-dev \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

USER frappe

WORKDIR /home/frappe/frappe-bench

# Copy all apps directory
COPY --chown=frappe:frappe ./apps /home/frappe/frappe-bench/apps

# Install all custom apps dynamically
RUN for app in apps/*; do \
      if [ -d "$app" ] && [ "$app" != "apps/frappe" ] && [ "$app" != "apps/erpnext" ]; then \
        app_name=$(basename "$app"); \
        if [ -f "$app/pyproject.toml" ] || [ -f "$app/setup.py" ]; then \
          echo "Installing $app_name..."; \
          pip install --no-cache-dir -e "$app"; \
          # Register the app name so 'bench' knows it exists
          printf "\n%s\n" "$app_name" >> /home/frappe/frappe-bench/sites/apps.txt; \
        fi \
      fi \
    done

RUN sed -i '/^$/d' /home/frappe/frappe-bench/sites/apps.txt

# Verify installed apps
RUN echo "Custom apps in sites/apps.txt:" && cat /home/frappe/frappe-bench/sites/apps.txt

WORKDIR /home/frappe/frappe-bench