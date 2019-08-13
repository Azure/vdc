FROM microsoft/azure-cli:2.0.34
WORKDIR /usr/src/app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --upgrade pip && \
    apk update && \
    apk add tzdata && \
    cp /usr/share/zoneinfo/America/Los_Angeles /etc/localtime && \
    echo "America/Los_Angeles" >  /etc/timezone
COPY . .
