# Python 3.9+ official slim image for a small, secure base
FROM python:3.11-slim

# Prevent Python from writing .pyc files and enable unbuffered logs
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set working directory
WORKDIR /app

# Install curl for container-level health checks and troubleshooting
# Using --no-install-recommends to keep image slim and remove apt lists to reduce layer size
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies first to leverage Docker layer caching
# TODO: This optimizes rebuilds by only reinstalling deps when requirements.txt changes
COPY analytics/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Create a non-root user and group for better security
RUN useradd -ms /bin/bash -u 10001 appuser

# Copy application code
COPY analytics/ /app/
RUN chown -R appuser:appuser /app

# Expose Flask port
# TODO: If your app uses a different port, update here and in Kubernetes manifests
EXPOSE 5153

# Drop privileges to run as non-root user
USER appuser

# Configure a container-level health check hitting the Flask health endpoint
# TODO: Adjust path if your health endpoint differs from /health_check
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS http://127.0.0.1:5153/health_check || exit 1

# Start the application
# TODO: If your app entrypoint differs, adjust the command below
CMD ["python", "app.py"]
