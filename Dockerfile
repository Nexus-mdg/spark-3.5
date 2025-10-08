# Multi-stage build for security hardening
# Stage 1: Build stage - download and prepare Spark
FROM ubuntu:22.04 AS builder

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV SPARK_VERSION=3.5.3
ENV HADOOP_VERSION=3
ENV SPARK_HOME=/opt/spark

# Install only necessary packages for downloading and extracting Spark
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download and extract Apache Spark 3.5.3
RUN wget -q https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    tar -xzf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} ${SPARK_HOME} && \
    rm spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

# Stage 2: Runtime stage - minimal final image
FROM ubuntu:22.04

# Set environment variables
ENV SPARK_VERSION=3.5.3
ENV HADOOP_VERSION=3
ENV SPARK_HOME=/opt/spark
ENV PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
ENV PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.9.7-src.zip:$PYTHONPATH

# Default Spark configuration environment variables
ENV SPARK_MODE=master
ENV SPARK_MASTER_HOST=localhost
ENV SPARK_MASTER_PORT=7077
ENV SPARK_MASTER_WEBUI_PORT=8080
ENV SPARK_WORKER_WEBUI_PORT=8081
ENV PYSPARK_PYTHON=python3

# Install only runtime dependencies (no wget, use JRE instead of JDK, minimal packages)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    gnupg && \
    add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    openjdk-11-jre-headless \
    python3.12 \
    python3.12-venv \
    procps && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Copy Spark from builder stage
COPY --from=builder ${SPARK_HOME} ${SPARK_HOME}

# Create spark user and group (non-root)
RUN groupadd -r spark --gid=1001 && \
    useradd -r -g spark --uid=1001 --home-dir=/home/spark --shell=/bin/bash spark && \
    mkdir -p /home/spark && \
    chown -R spark:spark /home/spark

# Create necessary directories with proper ownership
RUN mkdir -p /opt/spark/data /opt/spark/apps /opt/spark/work /opt/spark/logs && \
    chown -R spark:spark /opt/spark

# Create working directory
WORKDIR /workspace
RUN chown spark:spark /workspace

# Copy requirements.txt and build script
COPY --chown=spark:spark requirements.txt /workspace/
COPY --chown=spark:spark build_and_test.sh /workspace/
COPY --chown=spark:spark entrypoint.sh /opt/spark/

# Make scripts executable
RUN chmod +x /workspace/build_and_test.sh && \
    chmod +x /opt/spark/entrypoint.sh

# Expose Spark ports
# Master Web UI
EXPOSE 8080
# Master communication
EXPOSE 7077
# Worker Web UI
EXPOSE 8081
# Application UI
EXPOSE 4040

# Switch to non-root user
USER spark

# Set entrypoint
ENTRYPOINT ["/opt/spark/entrypoint.sh"]
