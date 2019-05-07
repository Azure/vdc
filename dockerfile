FROM microsoft/azure-cli
WORKDIR /usr/src/app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt && \
    pip freeze | grep azure | xargs pip uninstall -y && \
    pip freeze | grep msrest | xargs pip uninstall -y && \
    pip install azure-cli && \
    pip install --upgrade pip
COPY . .
