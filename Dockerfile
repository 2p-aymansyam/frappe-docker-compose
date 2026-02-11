FROM frappe/erpnext:v15.95.1

USER root

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    python3-dev \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN chown -R frappe:frappe /home/frappe/frappe-bench/apps
USER frappe
WORKDIR /home/frappe/frappe-bench

# Just create the apps.txt dynamically - don't pip install yet
COPY --chown=frappe:frappe ./apps /tmp/apps_copy

RUN \
    # 1. Your logic: Generate the apps.txt file
    ls -1 /tmp/apps_copy | grep -vxE ' ' > /home/frappe/frappe-bench/sites/apps.txt && \
    \
    # 2. Critical Step: Move code and install so Python can find the modules
    for app in $(cat /home/frappe/frappe-bench/sites/apps.txt); do \
        mv /tmp/apps_copy/$app /home/frappe/frappe-bench/apps/ && \
        /home/frappe/frappe-bench/env/bin/pip install -e /home/frappe/frappe-bench/apps/$app; \
    done && \
    \
    # 3. Cleanup
    rm -rf /tmp/apps_copy