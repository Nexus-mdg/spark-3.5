#!/bin/bash
set -e

# Default values
export SPARK_MODE=${SPARK_MODE:-master}
export SPARK_MASTER_HOST=${SPARK_MASTER_HOST:-localhost}
export SPARK_MASTER_PORT=${SPARK_MASTER_PORT:-7077}
export SPARK_MASTER_WEBUI_PORT=${SPARK_MASTER_WEBUI_PORT:-8080}
export SPARK_WORKER_WEBUI_PORT=${SPARK_WORKER_WEBUI_PORT:-8081}
export SPARK_MASTER_URL=${SPARK_MASTER_URL:-spark://${SPARK_MASTER_HOST}:${SPARK_MASTER_PORT}}
export PYSPARK_PYTHON=${PYSPARK_PYTHON:-python3}

# Security settings
export SPARK_RPC_AUTHENTICATION_ENABLED=${SPARK_RPC_AUTHENTICATION_ENABLED:-no}
export SPARK_RPC_ENCRYPTION_ENABLED=${SPARK_RPC_ENCRYPTION_ENABLED:-no}
export SPARK_LOCAL_STORAGE_ENCRYPTION_ENABLED=${SPARK_LOCAL_STORAGE_ENCRYPTION_ENABLED:-no}
export SPARK_SSL_ENABLED=${SPARK_SSL_ENABLED:-no}

# Create necessary directories
mkdir -p /opt/spark/data
mkdir -p /opt/spark/apps
mkdir -p /opt/spark/work
mkdir -p /opt/spark/logs

# Set Spark configuration based on environment variables
SPARK_CONF_FILE="${SPARK_HOME}/conf/spark-defaults.conf"
if [ ! -f "${SPARK_CONF_FILE}" ]; then
    cp "${SPARK_HOME}/conf/spark-defaults.conf.template" "${SPARK_CONF_FILE}" 2>/dev/null || touch "${SPARK_CONF_FILE}"
fi

# Configure RPC authentication
if [ "${SPARK_RPC_AUTHENTICATION_ENABLED}" = "yes" ]; then
    echo "spark.authenticate true" >> "${SPARK_CONF_FILE}"
fi

# Configure RPC encryption
if [ "${SPARK_RPC_ENCRYPTION_ENABLED}" = "yes" ]; then
    echo "spark.network.crypto.enabled true" >> "${SPARK_CONF_FILE}"
fi

# Configure local storage encryption
if [ "${SPARK_LOCAL_STORAGE_ENCRYPTION_ENABLED}" = "yes" ]; then
    echo "spark.io.encryption.enabled true" >> "${SPARK_CONF_FILE}"
fi

# Configure SSL
if [ "${SPARK_SSL_ENABLED}" = "yes" ]; then
    echo "spark.ssl.enabled true" >> "${SPARK_CONF_FILE}"
fi

# Set PySpark Python
echo "spark.pyspark.python ${PYSPARK_PYTHON}" >> "${SPARK_CONF_FILE}"
echo "spark.pyspark.driver.python ${PYSPARK_PYTHON}" >> "${SPARK_CONF_FILE}"

echo "Starting Spark in ${SPARK_MODE} mode..."

if [ "${SPARK_MODE}" = "master" ]; then
    echo "Starting Spark Master on ${SPARK_MASTER_HOST}:${SPARK_MASTER_PORT}"
    echo "Web UI will be available on port ${SPARK_MASTER_WEBUI_PORT}"

    ${SPARK_HOME}/sbin/start-master.sh \
        --host ${SPARK_MASTER_HOST} \
        --port ${SPARK_MASTER_PORT} \
        --webui-port ${SPARK_MASTER_WEBUI_PORT}

    # Keep container running
    exec tail -f ${SPARK_HOME}/logs/*master*.out

elif [ "${SPARK_MODE}" = "worker" ]; then
    echo "Starting Spark Worker connecting to ${SPARK_MASTER_URL}"
    echo "Worker Web UI will be available on port ${SPARK_WORKER_WEBUI_PORT}"

    ${SPARK_HOME}/sbin/start-worker.sh \
        ${SPARK_MASTER_URL} \
        --webui-port ${SPARK_WORKER_WEBUI_PORT}

    # Keep container running
    exec tail -f ${SPARK_HOME}/logs/*worker*.out

else
    echo "Invalid SPARK_MODE: ${SPARK_MODE}. Must be 'master' or 'worker'"
    exit 1
fi
