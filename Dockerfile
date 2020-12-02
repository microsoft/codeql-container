FROM ubuntu:20.04 AS codeql_base

ARG skip_compile=false

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# tzdata install needs to be non-interactive
ENV DEBIAN_FRONTEND=noninteractive

# install/update basics and python
# hadolint ignore=SC1072,DL3008
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    	software-properties-common \
    	vim \
    	curl \
    	git \
    	build-essential \
    	unzip \
    	apt-transport-https \
        python3.8 \
    	python3-venv \
    	python3-pip \
    	python3-setuptools \
        python3-dev \
    	gnupg \
    	g++ \
    	make \
    	gcc \
    	apt-utils \
        rsync \
    	file \
        dos2unix \
        sudo \
        jq \
    	gettext && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* && \
        ln -s /usr/bin/python3.8 /usr/bin/python && \
        ln -s /usr/bin/pip3 /usr/bin/pip

# install the zscalar ca cert
COPY Zscaler-Root-CA.pem .
RUN openssl x509 -inform pem -in Zscaler-Root-CA.pem -out /usr/local/share/ca-certificates/Zscaler-Root-CA.crt \
    && update-ca-certificates \
	&& pip config set global.cert /etc/ssl/certs/ca-certificates.crt

# Install .NET Core for tools/builds
WORKDIR /tmp
# hadolint ignore=DL3008,DL3015
RUN curl https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -s -L -o packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y apt-transport-https && \
    apt-get update && \
    apt-get install -y dotnet-sdk-3.1 && \
    rm packages-microsoft-prod.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# hadolint ignore=DL3004,DL4006
RUN curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash - \
    && sudo apt-get install --no-install-recommends -y nodejs \
    && sudo apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Clone our setup and run scripts
#RUN git clone https://github.com/microsoft/codeql-container /usr/local/startup_scripts
RUN mkdir -p /usr/local/startup_scripts
COPY container /usr/local/startup_scripts/
# hadolint ignore=DL3013
RUN pip3 install --upgrade pip \
    && pip3 install -r /usr/local/startup_scripts/requirements.txt

# Install latest codeQL
ENV CODEQL_HOME /usr/local/codeql-home
# record the latest version of the codeql-cli
RUN python3 /usr/local/startup_scripts/get-latest-codeql-version.py > /tmp/codeql_version
RUN mkdir -p ${CODEQL_HOME} \
    ${CODEQL_HOME}/codeql-repo \
    ${CODEQL_HOME}/codeql-go-repo \
    /opt/codeql

# get the latest codeql queries and record the HEAD
RUN git clone https://github.com/github/codeql ${CODEQL_HOME}/codeql-repo && \
    git --git-dir ${CODEQL_HOME}/codeql-repo/.git log --pretty=reference -1 > /opt/codeql/codeql-repo-last-commit
RUN git clone https://github.com/github/codeql-go ${CODEQL_HOME}/codeql-go-repo && \
    git --git-dir ${CODEQL_HOME}/codeql-go-repo/.git log --pretty=reference -1 > /opt/codeql/codeql-go-repo-last-commit

# hadolint ignore=SC2086
RUN CODEQL_VERSION=$(cat /tmp/codeql_version) && \
    curl https://github.com/github/codeql-cli-binaries/releases/download/${CODEQL_VERSION}/codeql-linux64.zip -s -L -o /tmp/codeql_linux.zip && \
    unzip /tmp/codeql_linux.zip -d ${CODEQL_HOME} && \
    rm /tmp/codeql_linux.zip

ENV PATH="${CODEQL_HOME}/codeql:${PATH}"
ENV _JAVA_OPTIONS="-Xmx2g"

# Pre-compile our queries to save time later
RUN [ "${skip_compile}" != "true" ] && codeql query compile --threads=0 ${CODEQL_HOME}/codeql-repo/javascript/ql/src/codeql-suites/*.qls || echo "Skipping compile..."

ENV PYTHONIOENCODING=utf-8
ENTRYPOINT ["python3", "/usr/local/startup_scripts/startup.py"]
