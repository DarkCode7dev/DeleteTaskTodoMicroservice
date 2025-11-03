FROM python:3.9

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies and ODBC drivers
RUN apt-get update && \
    apt-get install -y curl gnupg2 apt-transport-https && \
    
    # Add Microsoft repo for ODBC SQL driver
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/debian/12/prod bookworm main" \
    > /etc/apt/sources.list.d/mssql-release.list && \
    
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql18 && \
    apt-get install -y unixodbc unixodbc-dev && \
    
    # Update linker cache
    echo "/opt/microsoft/msodbcsql18/lib64" > /etc/ld.so.conf.d/msodbcsql18.conf && \
    ldconfig && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy application files
COPY requirements.txt .
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

COPY . .

# Set environment variables
ENV LD_LIBRARY_PATH="/opt/microsoft/msodbcsql18/lib64:${LD_LIBRARY_PATH}"

EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]