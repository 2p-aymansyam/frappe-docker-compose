FROM frappe/erpnext:v15.95.1

USER root

# Install system dependencies required for building Python packages
# Add any specific libraries your custom apps need here (e.g., libldap2-dev, libsasl2-dev)
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    python3-dev \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

USER frappe