# Docker Image Rebuild and Push Guide

This guide explains how to rebuild and push the Spark 3.5 Docker image after the access fixes have been applied.

## Quick Start

### Option 1: Automatic Build via CI/CD (Recommended)

The project uses GitHub Actions to automatically build and push images. Simply merge this PR to the `main` branch, and the image will be built and pushed automatically to GitHub Container Registry.

**Steps:**
1. Review and merge the PR
2. GitHub Actions will automatically:
   - Build the Docker image
   - Run tests
   - Push to `ghcr.io/nexus-mdg/spark-3.5:latest`
   - Create version tags if applicable

**Monitoring:**
- Check workflow status at: https://github.com/Nexus-mdg/spark-3.5/actions
- Workflow file: `.github/workflows/docker-build.yml`

### Option 2: Manual Local Build

If you need to build and test locally before merging:

```bash
# Clone the repository
git clone https://github.com/Nexus-mdg/spark-3.5.git
cd spark-3.5

# Build the image
docker build -t spark-3.5:local .

# Test the image - Master mode
docker run -d --name spark-master-test \
  -p 8080:8080 -p 7077:7077 \
  -e SPARK_MODE=master \
  spark-3.5:local

# Check logs
docker logs -f spark-master-test

# Access Web UI
# Open http://localhost:8080 in your browser

# Clean up
docker stop spark-master-test
docker rm spark-master-test
```

### Option 3: Manual Push to Registry

If you have permissions to push to the GitHub Container Registry:

```bash
# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Build with proper tags
docker build -t ghcr.io/nexus-mdg/spark-3.5:latest .
docker build -t ghcr.io/nexus-mdg/spark-3.5:v3.5.3 .

# Push to registry
docker push ghcr.io/nexus-mdg/spark-3.5:latest
docker push ghcr.io/nexus-mdg/spark-3.5:v3.5.3
```

## Verification After Push

### 1. Pull and Test the New Image

```bash
# Pull the latest image
docker pull ghcr.io/nexus-mdg/spark-3.5:latest

# Run quick test
docker run --rm ghcr.io/nexus-mdg/spark-3.5:latest whoami
# Should output: spark

# Test Spark access
docker run --rm ghcr.io/nexus-mdg/spark-3.5:latest \
  ls -la /opt/spark/conf
# Should show spark:spark ownership
```

### 2. Test with Docker Compose

```bash
# Create .env file if needed
cp .env.example .env

# Start cluster
docker-compose pull
docker-compose up -d

# Check status
docker-compose ps
docker-compose logs

# Access UIs
# Master: http://localhost:8080
# Worker: http://localhost:8081

# Cleanup
docker-compose down
```

### 3. Submit a Test Job

```bash
# Create a simple test script
cat > /tmp/test_spark.py << 'EOF'
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("AccessTest") \
    .getOrCreate()

df = spark.range(10)
print(f"Count: {df.count()}")
print("Spark access test successful!")

spark.stop()
EOF

# Submit to running cluster
docker exec spark-master-test \
  /opt/spark/bin/spark-submit \
  --master local[*] \
  /tmp/test_spark.py
```

## What Changed in This Build

The fixes in this build address the following issues:

1. **Conf Directory Permissions**: `/opt/spark/conf` now has proper spark user ownership
2. **Config File Creation**: Improved error handling when creating spark-defaults.conf
3. **Log Monitoring**: Added retry logic to wait for log files (prevents container crashes)
4. **Container Stability**: Containers now stay running even if logs are delayed

See `FIXES.md` for detailed technical information.

## Troubleshooting

### Build Fails with "wget: command not found"

This should not happen in the builder stage. Check that you're using the correct Dockerfile and that the builder stage is properly installing wget.

### Permission Errors at Runtime

Verify that the spark user owns all necessary directories:
```bash
docker run --rm ghcr.io/nexus-mdg/spark-3.5:latest \
  ls -la /opt/spark/
```

### Container Exits Immediately

Check the logs:
```bash
docker logs <container-name>
```

The fixes should prevent immediate exits. If it still happens, it may indicate a different issue.

### Cannot Access Web UI

Ensure ports are properly mapped:
```bash
docker run -p 8080:8080 -p 7077:7077 ...
```

Check that no other services are using these ports:
```bash
netstat -tlnp | grep 8080
```

## Support

For issues or questions:
- Open an issue at: https://github.com/Nexus-mdg/spark-3.5/issues
- Check documentation in: README.md, SECURITY.md, FIXES.md
- Review workflows at: .github/workflows/

## Next Steps After Push

1. Update any dependent projects to use the new image
2. Monitor for any issues in production
3. Update documentation if needed
4. Consider creating a release tag for this version
