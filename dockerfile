FROM ubuntu
WORKDIR /usr/src/app
COPY . ./
RUN  apt-get update \
  && apt-get install -y wget \
  && rm -rf /var/lib/apt/lists \
  && wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb \
  && dpkg -i packages-microsoft-prod.deb \
  && apt-get update \
  && apt-get install -y powershell \
  && pwsh -Command "Install-Module -Name Az -Force" \
  && pwsh -Command "Install-Module -Name Pester -Force" \
  && pwsh -Command "Install-Module -Name Az.ResourceGraph -Force"
ENTRYPOINT [ "pwsh" ]
