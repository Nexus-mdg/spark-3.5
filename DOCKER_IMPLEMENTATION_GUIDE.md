# Docker Image Implementation Guide

This document outlines what has been implemented in this repository for building secure, production-ready Docker images. Use this as a reference when applying similar patterns to new repositories.

## Security Hardening Implementation

### Multi-Stage Builds
- **Two-stage Dockerfile structure implemented**:
  - Stage 1 (Builder): Download and extract application binaries with minimal tools (wget, ca-certificates)
  - Stage 2 (Runtime): Clean final image with only runtime dependencies
- **Benefits**: Reduced image size, smaller attack surface, no build tools in production image
- **Implementation**: Separate `FROM` statements for builder and runtime stages, use `COPY --from=builder`

### Non-Root User Execution
- **Created dedicated service user**: `spark` user with UID/GID 1001
- **All processes run as non-root**: Used `USER spark` directive before ENTRYPOINT
- **Proper ownership**: All application files and directories owned by service user
- **Home directory setup**: Created `/home/spark` with correct permissions
- **Benefits**: Limits container compromise damage, prevents privilege escalation

### Minimal Runtime Dependencies
- **Used `--no-install-recommends`**: Prevents installation of unnecessary recommended packages
- **JRE instead of JDK**: Switched from `openjdk-11-jdk` to `openjdk-11-jre-headless`
- **Removed build tools**: No wget, tar, or compilers in final image
- **Cleanup after installation**: Removed apt cache and lists (`apt-get clean && rm -rf /var/lib/apt/lists/*`)
- **Benefits**: ~200-300MB smaller image, fewer vulnerabilities, no development tools available

### Proper File Permissions
- **Directory creation with ownership**: Used `mkdir -p` with `chown` in same layer
- **Copy with ownership**: Used `COPY --chown=spark:spark` for all application files
- **Executable permissions**: Applied `chmod +x` only to scripts that need execution
- **Working directory**: Created `/workspace` with proper ownership
- **Application directories**: Created `/opt/spark/data`, `/opt/spark/apps`, `/opt/spark/work`, `/opt/spark/logs`

### Build Context Optimization
- **Created `.dockerignore` file** to exclude:
  - Version control files (`.git`, `.gitignore`)
  - Documentation (`README.md`, `LICENSE`)
  - Environment files (`.env`, `.env.example`)
  - Python artifacts (`venv/`, `__pycache__/`, `*.pyc`)
  - Virtual environments (`env/`, `ENV/`)
  - IDE files (`.vscode/`, `.idea/`, `*.swp`)
  - OS files (`.DS_Store`, `Thumbs.db`)
  - Application data directories (`spark-apps/`, `metastore_db/`)
- **Benefits**: Faster builds, prevents accidental secret inclusion, smaller build context

## Application Configuration

### Environment Variables
- **Default configuration via ENV directives** in Dockerfile:
  - Application mode selection (`SPARK_MODE=master`)
  - Networking configuration (`SPARK_MASTER_HOST`, `SPARK_MASTER_PORT`)
  - UI ports (`SPARK_MASTER_WEBUI_PORT`, `SPARK_WORKER_WEBUI_PORT`)
  - Security settings (authentication, encryption, SSL flags)
  - Python configuration (`PYSPARK_PYTHON=python3`)
- **Runtime override support**: All environment variables can be overridden at container runtime

### Configuration File Template
- **Example configuration provided**: `.env.example` with all configurable options
- **Documentation**: Each variable documented with purpose and default value
- **Easy setup**: Users copy `.env.example` to `.env` and customize

### Entrypoint Script
- **Flexible startup logic**: `entrypoint.sh` handles different operational modes
- **Dynamic configuration**: Generates `spark-defaults.conf` from environment variables
- **Directory creation**: Creates necessary runtime directories
- **Security configuration**: Applies authentication, encryption, and SSL settings dynamically
- **Mode-specific startup**: Different logic for master vs worker modes
- **Process management**: Uses `exec` for proper signal handling

### Exposed Ports
- **Documented port usage**:
  - `7077`: Master communication port
  - `8080`: Master Web UI
  - `8081`: Worker Web UI
  - `4040`: Application UI
- **EXPOSE directives**: All ports declared in Dockerfile for documentation

## Volume Mounts

### Persistent Data Directories
- **Application data**: `/opt/spark/data` for persistent storage
- **User applications**: `/opt/spark/apps` for Spark application deployment
- **Worker directory**: `/opt/spark/work` for Spark worker operations
- **Logs**: `/opt/spark/logs` for application and service logs

### Volume Configuration
- **Docker Compose integration**: Named volume for data persistence
- **Bind mounts**: Support for mounting host directories (e.g., `./spark-apps`)
- **Proper ownership**: All directories owned by non-root service user

## Multi-Container Orchestration

### Docker Compose Setup
- **Multi-service configuration**: Master and worker services defined
- **Network mode**: Host networking for simplified cluster communication
- **Environment-based configuration**: Uses `.env` file for customization
- **Service dependencies**: Worker depends on master service
- **Restart policy**: `restart: always` for production reliability
- **Volume sharing**: Both services share application directory

### Service Configuration
- **Master service**: Runs in master mode, exposes Web UI on port 8080
- **Worker service**: Runs in worker mode, connects to master, Web UI on port 8081
- **Named volumes**: Persistent data storage for master service
- **Bind mounts**: Shared application directory between host and containers

## CI/CD Automation

### Docker Image Build Pipeline
- **GitHub Actions workflow**: `.github/workflows/docker-build.yml`
- **Multi-trigger support**:
  - Push to main branch
  - Version tags (`v*`)
  - Pull requests (build only, no push)
  - Manual workflow dispatch
- **GitHub Container Registry integration**: Automated push to `ghcr.io`
- **Docker Buildx**: Support for multi-platform builds
- **Image tagging strategy**:
  - Branch-based tags (`main`)
  - Semantic version tags (`v1.2.3`, `1.2`, `1`)
  - Latest tag for default branch
- **Build caching**: GitHub Actions cache for faster builds

### Compatibility Testing
- **Automated testing workflow**: `.github/workflows/pyspark-compatibility.yml`
- **Test triggers**:
  - Push to main/develop branches
  - Pull requests
  - Manual workflow dispatch
- **Test environment**:
  - Python 3.10 setup
  - Java 11 (Temurin distribution)
  - Apache Spark 3.5.3 download
- **Virtual environment testing**: Ensures Python dependencies work correctly
- **Functional verification**: Creates SparkSession and tests DataFrame operations
- **Version compatibility**: Validates PySpark 3.5.6 works with Spark 3.5.3

## Security Documentation

### Comprehensive Security Guide
- **Dedicated SECURITY.md file** documenting:
  - All implemented security improvements
  - Benefits of each security measure
  - Reference to specific Dockerfile lines
  - Security checklist compliance table
  - Before/after comparison metrics
  - Verification steps for users

### Vulnerability Scanning Documentation
- **Trivy integration documented**: Command to scan images for vulnerabilities
- **Grype integration documented**: Alternative scanning tool usage
- **Regular scanning recommended**: Part of CI/CD pipeline guidance

### Image Signing Guidance
- **Docker Content Trust**: Instructions for enabling DCT and pushing signed images
- **Cosign integration**: Commands for key generation, signing, and verification
- **Production recommendations**: Guidance on mandatory signing for production

### Update and Maintenance
- **Regular rebuild process**: Documented `docker build --no-cache` for fresh images
- **Security monitoring**: Links to Ubuntu, Spark, and Java security advisories
- **CI/CD automation**: Guidance on scheduled builds and vulnerability scanning

## Testing and Validation

### Build and Test Script
- **Compatibility test script**: `build_and_test.sh` for validating PySpark
- **Virtual environment creation**: Isolated Python environment for testing
- **Dependency installation**: Installs from `requirements.txt`
- **Functional testing**: Creates DataFrame and verifies operations
- **Version verification**: Confirms PySpark and Spark version compatibility

### Requirements Management
- **requirements.txt**: Specifies `pyspark==3.5.6`
- **Version pinning**: Ensures reproducible builds
- **Dependency documentation**: Clear specification of Python dependencies

## Documentation

### README Structure
- **Comprehensive user documentation** including:
  - Quick start guide
  - Pre-built image usage from GitHub Container Registry
  - Local build instructions
  - Docker Compose setup and usage
  - Manual container execution examples
  - Environment variable reference
  - Volume mount documentation
  - Port exposure listing
  - Security hardening summary
  - Compatibility comparison with reference images
  - Example application submission

### Badge Display
- **CI/CD status badges**: Shows build and test workflow status
- **Visual indicators**: Users can quickly see if builds are passing

### Multiple Usage Patterns
- **Pre-built image usage**: Pull from `ghcr.io/nexus-mdg/spark-3.5:latest`
- **Local build**: Instructions for building custom images
- **Docker Compose**: Complete cluster setup
- **Manual execution**: Direct `docker run` commands
- **Interactive mode**: Shell access for debugging

## Image Publishing

### GitHub Container Registry
- **Automated publishing**: Images pushed on main branch and tags
- **Public availability**: Images accessible via `ghcr.io`
- **Tag strategy**: Multiple tags (latest, branch, semver)
- **Authentication**: Uses GitHub token for registry access

### Custom Publishing
- **Documentation provided** for users to publish their own versions
- **Tagging instructions**: How to tag images for custom registries
- **Registry login**: Commands for authentication
- **Push instructions**: Complete workflow for custom publishing

## Base Image Selection

### Ubuntu 22.04 LTS
- **Long-term support**: Stable base with extended security updates
- **Wide compatibility**: Well-supported across cloud providers
- **Package availability**: Extensive apt repository
- **Security updates**: Regular patches and updates

## Summary Checklist

When implementing similar Docker images, ensure you have:

- [ ] Multi-stage Dockerfile with separate builder and runtime stages
- [ ] Non-root user created and used for all processes
- [ ] Minimal runtime dependencies (--no-install-recommends, JRE not JDK)
- [ ] Proper file permissions and ownership throughout
- [ ] .dockerignore file to optimize build context
- [ ] Environment variables for runtime configuration
- [ ] Entrypoint script for flexible startup modes
- [ ] Volume mount points for persistent data
- [ ] Exposed ports documented and declared
- [ ] Docker Compose configuration for orchestration
- [ ] CI/CD pipeline for automated builds
- [ ] Automated testing workflow
- [ ] Comprehensive README documentation
- [ ] Dedicated SECURITY.md with implementation details
- [ ] Vulnerability scanning guidance (Trivy/Grype)
- [ ] Image signing documentation (DCT/Cosign)
- [ ] Example .env file for configuration
- [ ] GitHub Container Registry publishing setup
- [ ] Build badges in README
- [ ] Requirements file for dependencies
- [ ] Test script for validation

## Key Principles Applied

1. **Security First**: Every decision prioritizes security (non-root, minimal deps, multi-stage)
2. **Documentation**: Extensive documentation for users and maintainers
3. **Automation**: CI/CD for builds, tests, and publishing
4. **Flexibility**: Configuration via environment variables
5. **Production Ready**: Restart policies, health checks consideration, proper signal handling
6. **Transparency**: Clear documentation of what's included and why
7. **Best Practices**: Follows Docker and security community recommendations
8. **Maintainability**: Clear structure, commented Dockerfile, comprehensive docs
