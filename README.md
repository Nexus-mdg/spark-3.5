# spark-3.5

[![PySpark 3.5.6 Compatibility Test](https://github.com/Nexus-mdg/spark-3.5/actions/workflows/pyspark-compatibility.yml/badge.svg)](https://github.com/Nexus-mdg/spark-3.5/actions/workflows/pyspark-compatibility.yml)
[![Build and Push Docker Image](https://github.com/Nexus-mdg/spark-3.5/actions/workflows/docker-build.yml/badge.svg)](https://github.com/Nexus-mdg/spark-3.5/actions/workflows/docker-build.yml)

Docker image for Apache Spark 3.5 with PySpark 3.5.6 compatibility testing.

This image provides the same features as bitnami/spark:3.5, including master/worker mode support, security configurations, and volume mounting.

## Contents

- **Dockerfile**: Hardened Ubuntu-based Docker image with Apache Spark 3.5.3 (multi-stage build, non-root user)
- **requirements.txt**: Python dependencies (pyspark==3.5.6)
- **build_and_test.sh**: Shell script to test PySpark compatibility using a virtual environment
- **entrypoint.sh**: Entry point script to start Spark in master or worker mode
- **docker-compose.yml**: Docker Compose configuration for multi-node setup
- **.env.example**: Example environment variables configuration
- **.dockerignore**: Excludes unnecessary files from Docker build context
- **SECURITY.md**: Detailed documentation of security improvements and best practices

## Features

- Based on Ubuntu 22.04
- Apache Spark 3.5.3 with Hadoop 3
- Python 3 with virtual environment support
- curl utility pre-installed
- OpenJDK 11 JRE (runtime-only, no compiler/dev tools)
- **Master/Worker mode support** - Run as Spark master or worker
- **Configurable security** - RPC authentication, encryption, SSL
- **Volume support** - Mount data and application directories
- **Environment-based configuration** - Fully configurable via environment variables
- **Security hardened**:
  - Multi-stage build (build tools not included in final image)
  - Runs as non-root user (spark user, UID/GID 1001)
  - Minimal runtime dependencies (no wget, no compilers)
  - Proper file permissions and ownership
  - Uses JRE instead of JDK for smaller attack surface

## Using the Pre-built Docker Image

Pull the pre-built image from GitHub Container Registry:

```bash
docker pull ghcr.io/nexus-mdg/spark-3.5:latest
```

Available tags:
- `latest` - Latest build from main branch
- `main` - Latest build from main branch
- `v*` - Specific version tags (e.g., `v3.5.3`)

### Using the Image

Once pulled, you can use it like the locally built image:

```bash
# Run as Spark Master
docker run -d \
  --name spark-master \
  --network host \
  -e SPARK_MODE=master \
  ghcr.io/nexus-mdg/spark-3.5:latest

# Run as Spark Worker
docker run -d \
  --name spark-worker \
  --network host \
  -e SPARK_MODE=worker \
  -e SPARK_MASTER_URL=spark://localhost:7077 \
  ghcr.io/nexus-mdg/spark-3.5:latest
```

## Building the Docker Image

If you prefer to build the image locally:

```bash
docker build -t spark-3.5:latest .
```

### Publishing Your Own Image

To push your own version to GitHub Container Registry:

```bash
# Tag your image
docker tag spark-3.5:latest ghcr.io/your-username/spark-3.5:latest

# Log in to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u your-username --password-stdin

# Push the image
docker push ghcr.io/your-username/spark-3.5:latest
```

Note: Replace `your-username` with your GitHub username and `$GITHUB_TOKEN` with a Personal Access Token that has `write:packages` permission.

### Keeping the Image Updated

To keep your image secure with the latest patches:

1. Regularly rebuild the image to get latest base image updates:
```bash
docker build --no-cache -t spark-3.5:latest .
```

2. Monitor for security advisories:
   - Ubuntu security updates: https://ubuntu.com/security/notices
   - Apache Spark security: https://spark.apache.org/security.html
   - Java/OpenJDK updates: Check Ubuntu repositories for JRE updates

3. Automate builds with CI/CD:
   - Set up scheduled builds (e.g., weekly) in your CI/CD pipeline
   - Run vulnerability scans as part of your build process

## Running with Docker Compose

### Setup

1. Copy the example environment file:
```bash
cp .env.example .env
```

2. Edit `.env` to configure your Spark cluster (optional)

3. Create the spark-apps directory for your applications:
```bash
mkdir -p spark-apps
```

### Start Spark Cluster (Master + Worker)

```bash
docker-compose up -d
```

This will start:
- **Spark Master** on port 8080 (Web UI) and 7077 (communication)
- **Spark Worker** on port 8081 (Web UI)

### Access Web UIs

- **Master Web UI**: http://localhost:8080
- **Worker Web UI**: http://localhost:8081

### Stop Cluster

```bash
docker-compose down
```

## Running the Container Manually

### As Spark Master

```bash
docker run -d \
  --name spark-master \
  --network host \
  -e SPARK_MODE=master \
  -e SPARK_MASTER_HOST=localhost \
  -e SPARK_MASTER_WEBUI_PORT=8080 \
  -v $(pwd)/spark-apps:/opt/spark/apps \
  spark-3.5:latest
```

### As Spark Worker

```bash
docker run -d \
  --name spark-worker \
  --network host \
  -e SPARK_MODE=worker \
  -e SPARK_MASTER_URL=spark://localhost:7077 \
  -e SPARK_WORKER_WEBUI_PORT=8081 \
  -v $(pwd)/spark-apps:/opt/spark/apps \
  spark-3.5:latest
```

### Interactive Mode (for testing)

```bash
docker run -it \
  -e SPARK_MODE=master \
  spark-3.5:latest \
  bash
```

Note: The container runs as the non-root `spark` user by default.

## Testing PySpark Compatibility

Inside the container (or on a system with the required dependencies), run:

```bash
./build_and_test.sh
```

This script will:
1. Create a Python virtual environment
2. Install pyspark==3.5.6 from requirements.txt
3. Test the PySpark installation with Apache Spark 3.5
4. Verify compatibility by creating and querying a sample DataFrame

## Environment Variables

### Spark Mode Configuration

- `SPARK_MODE`: Set to `master` or `worker` (default: `master`)
- `SPARK_MASTER_HOST`: Hostname for the Spark master (default: `localhost`)
- `SPARK_MASTER_PORT`: Port for Spark master communication (default: `7077`)
- `SPARK_MASTER_WEBUI_PORT`: Port for Spark master Web UI (default: `8080`)
- `SPARK_WORKER_WEBUI_PORT`: Port for Spark worker Web UI (default: `8081`)
- `SPARK_MASTER_URL`: URL to connect to Spark master (worker mode) (default: `spark://localhost:7077`)

### Security Configuration

- `SPARK_RPC_AUTHENTICATION_ENABLED`: Enable RPC authentication (default: `no`)
- `SPARK_RPC_ENCRYPTION_ENABLED`: Enable RPC encryption (default: `no`)
- `SPARK_LOCAL_STORAGE_ENCRYPTION_ENABLED`: Enable local storage encryption (default: `no`)
- `SPARK_SSL_ENABLED`: Enable SSL (default: `no`)

### Python Configuration

- `PYSPARK_PYTHON`: Python executable to use (default: `python3`)

## Volume Mounts

- `/opt/spark/data`: For Spark data storage
- `/opt/spark/apps`: For your Spark applications
- `/opt/spark/work`: Spark worker directory
- `/opt/spark/logs`: Spark logs

## Exposed Ports

- `7077`: Spark master communication port
- `8080`: Spark master Web UI
- `8081`: Spark worker Web UI
- `4040`: Spark application UI

## Compatibility with bitnami/spark:3.5

This image provides equivalent functionality to `bitnami/spark:3.5`:

| Feature | bitnami/spark:3.5 | This Image |
|---------|-------------------|------------|
| Spark Version | 3.5.x | 3.5.3 |
| Master/Worker Mode | ✓ | ✓ |
| Security Features | ✓ | ✓ |
| Volume Support | ✓ | ✓ |
| Environment Configuration | ✓ | ✓ |
| PySpark Support | ✓ | ✓ (3.5.6) |
| Web UI | ✓ | ✓ |

## Security Hardening

This image has been hardened following Docker security best practices:

### Multi-Stage Builds
The Dockerfile uses a two-stage build process:
- **Build stage**: Downloads and extracts Spark with minimal tools (wget, ca-certificates)
- **Runtime stage**: Only includes runtime dependencies, excluding build tools

This approach significantly reduces the final image size and attack surface.

### Non-Root User
The image runs as a non-root user `spark` (UID/GID 1001) instead of root. All Spark processes, files, and directories are owned by this user.

To access the container as the spark user:
```bash
docker exec -it -u spark spark-master bash
```

### Minimal Runtime Dependencies
- Uses `openjdk-11-jre-headless` (JRE only) instead of full JDK
- Installs packages with `--no-install-recommends` flag
- Removes `wget` and other build tools from runtime image
- Cleans up apt cache and lists to reduce image size

### Proper File Permissions
All Spark directories (`/opt/spark/*`, `/workspace`) are owned by the spark user with appropriate permissions.

### Scanning for Vulnerabilities
You can scan this image for vulnerabilities using free tools:

```bash
# Using Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image spark-3.5:latest

# Using Grype
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  anchore/grype:latest spark-3.5:latest
```

### Build Context Optimization
A `.dockerignore` file excludes unnecessary files from the build context (git files, documentation, virtual environments, etc.), reducing build time and preventing sensitive files from being included.

### Image Signing and Verification (Optional)

For production use, consider signing and verifying your images:

#### Using Docker Content Trust (DCT)
```bash
# Enable Docker Content Trust
export DOCKER_CONTENT_TRUST=1

# Push signed image
docker push your-registry/spark-3.5:latest

# Pull and verify signed image
docker pull your-registry/spark-3.5:latest
```

#### Using Cosign
```bash
# Install cosign (if not already installed)
# See https://docs.sigstore.dev/cosign/installation/

# Generate key pair (first time only)
cosign generate-key-pair

# Sign the image
cosign sign --key cosign.key your-registry/spark-3.5:latest

# Verify the image
cosign verify --key cosign.pub your-registry/spark-3.5:latest
```

## Example: Submitting a Spark Application

1. Place your PySpark application in the `spark-apps` directory
2. Submit it to the cluster:

```bash
docker exec spark-master spark-submit \
  --master spark://localhost:7077 \
  /opt/spark/apps/your_app.py
```

## Security

For detailed information about security hardening and best practices, see [SECURITY.md](SECURITY.md).

## License

See [LICENSE](LICENSE) file for details.