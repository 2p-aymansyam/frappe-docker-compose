FROM frappe/erpnext:v15.95.1

USER root

# 1. Install developer tools, Node.js (for frontend hot-reloading), and dos2unix
RUN apt-get update && apt-get install -y \
    curl git dos2unix build-essential python3-dev mariadb-client \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn \
    && rm -rf /var/lib/apt/lists/*

# 2. Ensure permissions are correct
RUN chown -R frappe:frappe /home/frappe/frappe-bench

# Create a symlink at /opt/sites pointing to the actual sites folder
# This fixes the relative path resolution for Vite builds in soft-linked apps
RUN ln -s /home/frappe/frappe-bench/sites /opt/sites

USER frappe
WORKDIR /home/frappe/frappe-bench

# 3. Bring in the entrypoint script and fix Windows line endings
COPY --chown=frappe:frappe entrypoint.sh /home/frappe/entrypoint.sh
RUN dos2unix /home/frappe/entrypoint.sh && chmod +x /home/frappe/entrypoint.sh

ENTRYPOINT ["/home/frappe/entrypoint.sh"]