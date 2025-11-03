FROM python:3.9

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY . .

RUN apt-get update && \
    apt-get install -y curl gnupg2 apt-transport-https unixodbc unixodbc-dev libodbc1 && \
    \
    # Add Microsoft repo for ODBC SQL driver
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/debian/12/prod bookworm main" \
        > /etc/apt/sources.list.d/mssql-release.list && \
    \
    # Install Microsoft ODBC driver
    apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql18 && \
    \
    # Force link and register ODBC library path
    ln -sf /opt/microsoft/msodbcsql18/lib64/libodbc.so.2 /usr/lib/x86_64-linux-gnu/libodbc.so.2 || true && \
    echo "/opt/microsoft/msodbcsql18/lib64" > /etc/ld.so.conf.d/msodbcsql18.conf && \
    ldconfig && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

# 🔥 Critical Fix: make pyodbc find the driver path
ENV LD_LIBRARY_PATH=/opt/microsoft/msodbcsql18/lib64:$LD_LIBRARY_PATH

EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
