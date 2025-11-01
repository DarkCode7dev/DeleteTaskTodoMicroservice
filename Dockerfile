# Use official Python base image
FROM python:3.9

# Set working directory
WORKDIR /app

# Copy application files
COPY . .

# Install system dependencies for ODBC + SQL Server
RUN apt-get update && apt-get install -y curl gnupg2 apt-transport-https unixodbc unixodbc-dev

# Add Microsoft’s GPG key and repository for Debian 11 (Bullseye)
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/debian/11/prod.list -o /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql18 && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose FastAPI port
EXPOSE 8000

# Run FastAPI app
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
