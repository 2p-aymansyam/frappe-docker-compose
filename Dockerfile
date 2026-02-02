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
# This will skip frappe and erpnext (already installed in base image)
# and install any other apps found in the apps directory
RUN for app in apps/*; do \
      if [ -d "$app" ] && [ "$app" != "apps/frappe" ] && [ "$app" != "apps/erpnext" ]; then \
        if [ -f "$app/pyproject.toml" ] || [ -f "$app/setup.py" ]; then \
          echo "Installing $app..."; \
          pip install --no-cache-dir -e "$app" || echo "Warning: Failed to install $app"; \
        else \
          echo "Skipping $app (no pyproject.toml or setup.py found)"; \
        fi \
      fi \
    done

# Verify installed apps
RUN echo "Installed custom apps:" && \
    pip list | grep -E "document-management-system|itsm" || echo "No custom apps detected"

WORKDIR /home/frappe/frappe-bench