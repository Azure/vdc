FROM microsoft/azure-cli:2.0.54
WORKDIR /usr/src/app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --upgrade pip
COPY . .
