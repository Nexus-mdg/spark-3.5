# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Fixed
- Fixed Spark access issues in Dockerfile and entrypoint.sh
  - Added explicit `/opt/spark/conf` directory creation with proper spark user ownership
  - Improved configuration file template handling with explicit error checking
  - Enhanced log file monitoring to wait for files to be created (up to 30 seconds)
  - Added fallback mechanism to keep container running even if log files don't appear immediately
  - Prevents container crashes when Spark processes are slow to start or log files use different naming patterns

### Changed
- entrypoint.sh now explicitly checks for template file existence before copying
- Log monitoring now uses a retry loop instead of direct wildcard expansion
- Container remains alive even if log files are not created within the expected time

## [Initial Release] - 2025-10-08

### Added
- Initial Docker image for Apache Spark 3.5.3
- Multi-stage build for security hardening
- Non-root user execution (spark user with UID/GID 1001)
- Support for master and worker modes
- Environment-based configuration
- Security features (RPC authentication, encryption, SSL support)
- Docker Compose setup for cluster deployment
- Compatibility with bitnami/spark:3.5
- Comprehensive security documentation
- CI/CD workflows for automated builds and testing
