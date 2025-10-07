# Use Ubuntu as base image
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
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

# Install required packages
RUN apt-get update && \
    apt-get install -y \
    curl \
    openjdk-11-jdk \
    python3 \
    python3-pip \
    python3-venv \
    wget \
    procps && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download and install Apache Spark 3.5.3
RUN wget -q https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    tar -xzf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} ${SPARK_HOME} && \
    rm spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Create necessary directories
RUN mkdir -p /opt/spark/data /opt/spark/apps /opt/spark/work /opt/spark/logs

# Create working directory
WORKDIR /workspace

# Copy requirements.txt and build script
COPY requirements.txt /workspace/
COPY build_and_test.sh /workspace/
COPY entrypoint.sh /opt/spark/

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

# Set entrypoint
ENTRYPOINT ["/opt/spark/entrypoint.sh"]
