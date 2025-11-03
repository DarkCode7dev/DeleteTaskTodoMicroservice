# Use official Python base image
FROM python:3.9

# Prevent Python from writing pyc files and buffering stdout
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Install all dependencies including Microsoft ODBC driver
RUN apt-get update && \
    apt-get install -y curl gnupg2 apt-transport-https unixodbc unixodbc-dev libodbc1 && \
    \
    # Add Microsoft repo for ODBC SQL driver
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/debian/12/prod bookworm main" \
        > /etc/apt/sources.list.d/mssql-release.list && \
    \
    # Install the Microsoft ODBC Driver 18 for SQL Server
    apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql18 && \
    \
    # 🔧 Fix: Link ODBC driver library for pyodbc to detect it properly
    ln -s /opt/microsoft/msodbcsql18/lib64/libodbc.so.2 /usr/lib/x86_64-linux-gnu/libodbc.so.2 || true && \
    \
    # Clean up apt cache
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

# Expose app port
EXPOSE 8000

# Run the FastAPI / Uvicorn app
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
