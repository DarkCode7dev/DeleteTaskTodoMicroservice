# Use Python 3.11 slim image as base
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    apt-transport-https \
    ca-certificates \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install unixodbc packages (this provides libodbc.so.2)
RUN apt-get update && apt-get install -y \
    unixodbc \
    unixodbc-dev \
    && rm -rf /var/lib/apt/lists/*

# Verify unixodbc library is installed
RUN find /usr -name "libodbc.so*" 2>/dev/null || echo "Library not found yet"

# Install Microsoft ODBC Driver for SQL Server
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
    && curl https://packages.microsoft.com/config/debian/$(lsb_release -rs)/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql18 \
    && rm -rf /var/lib/apt/lists/*

# Update library cache
RUN ldconfig

# Verify ODBC libraries are accessible
RUN ldconfig -p | grep odbc || (echo "ODBC libraries:" && find /usr -name "*odbc*" -type f 2>/dev/null | head -10)

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Test that pyodbc can import (this will fail the build if libraries are missing)
RUN python -c "import pyodbc; print('pyodbc imported successfully')" || \
    (echo "pyodbc import failed. Library locations:" && find /usr -name "libodbc.so*" 2>/dev/null && exit 1)

# Copy application code
COPY app.py .

# Expose port 8000
EXPOSE 8000

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Run the application using uvicorn
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
