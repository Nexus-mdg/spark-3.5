# spark-3.5

Docker image for Apache Spark 3.5 with PySpark 3.5.6 compatibility testing.

## Contents

- **Dockerfile**: Ubuntu-based Docker image with Apache Spark 3.5.3 and curl installed
- **requirements.txt**: Python dependencies (pyspark==3.5.6)
- **build_and_test.sh**: Shell script to test PySpark compatibility using a virtual environment

## Features

- Based on Ubuntu 22.04
- Apache Spark 3.5.3 with Hadoop 3
- Python 3 with virtual environment support
- curl utility pre-installed
- OpenJDK 11 for Spark

## Building the Docker Image

```bash
docker build -t spark-3.5:latest .
```

## Running the Container

```bash
docker run -it spark-3.5:latest
```

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

## Manual Testing

You can also test manually by running:

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Test PySpark
python3 -c "import pyspark; print(f'PySpark version: {pyspark.__version__}')"
```

## Environment Variables

The Dockerfile sets the following environment variables:
- `SPARK_HOME=/opt/spark`
- `JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64`
- `PYTHONPATH` includes Spark Python libraries

## License

See [LICENSE](LICENSE) file for details.