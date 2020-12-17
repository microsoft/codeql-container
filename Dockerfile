FROM ubuntu:20.04@sha256:4e4bc990609ed865e07afc8427c30ffdddca5153fd4e82c20d8f0783a291e241 AS codeql_base

ARG skip_compile=false

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# tzdata install needs to be non-interactive
ENV DEBIAN_FRONTEND=noninteractive


# install/update basics and python
# hadolint ignore=SC1072,DL3008,DL3004
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        curl \
        git \
        unzip \
        gnupg \
        apt-transport-https \
        python3-minimal \
        python3-pip \
        sudo && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* && \
        ln -s /usr/bin/python3.8 /usr/bin/python && \
        ln -s /usr/bin/pip3 /usr/bin/pip

# install the zscalar ca cert
COPY Zscaler-Root-CA.pem .
# hadolint ignore=DL3013
RUN openssl x509 -inform pem -in Zscaler-Root-CA.pem -out /usr/local/share/ca-certificates/Zscaler-Root-CA.crt \
    && update-ca-certificates \
    && python -m pip config set global.cert /etc/ssl/certs/ca-certificates.crt \
    && python -m pip install --upgrade pip

RUN curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash - && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Clone our setup and run scripts
RUN mkdir -p /usr/local/startup_scripts
COPY container /usr/local/startup_scripts/
RUN python -m pip install -r /usr/local/startup_scripts/requirements.txt

# Install latest codeQL
ENV CODEQL_HOME /usr/local/codeql-home
# record the latest version of the codeql-cli
RUN python3 /usr/local/startup_scripts/get-latest-codeql-version.py > /tmp/codeql_version
RUN mkdir -p ${CODEQL_HOME} \
    ${CODEQL_HOME}/codeql-repo \
    /opt/codeql

# get the latest codeql queries and record the HEAD
RUN git clone https://github.com/github/codeql ${CODEQL_HOME}/codeql-repo && \
    git --git-dir ${CODEQL_HOME}/codeql-repo/.git log --pretty=reference -1 > /opt/codeql/codeql-repo-last-commit

# hadolint ignore=SC2086
RUN CODEQL_VERSION=$(cat /tmp/codeql_version) && \
    curl https://github.com/github/codeql-cli-binaries/releases/download/${CODEQL_VERSION}/codeql-linux64.zip -s -L -o /tmp/codeql_linux.zip && \
    unzip /tmp/codeql_linux.zip -d ${CODEQL_HOME} && \
    rm /tmp/codeql_linux.zip

ENV PATH="${CODEQL_HOME}/codeql:${PATH}"

# Pre-compile our queries to save time later
RUN [ "${skip_compile}" != "true" ] && codeql query compile --threads=0 --ram=4096 ${CODEQL_HOME}/codeql-repo/javascript/ql/src/codeql-suites/*.qls || echo "Skipping JavaScript compile..."
RUN [ "${skip_compile}" != "true" ] && codeql query compile --threads=0 --ram=4096 ${CODEQL_HOME}/codeql-repo/java/ql/src/codeql-suites/*.qls || echo "Skipping Java compile..."

RUN find ${CODEQL_HOME} -name .git -type d -print0 | xargs -0 -I {} rm -rf "{}" \; && \
    rm -rf ${CODEQL_HOME}/codeql/cpp ${CODEQL_HOME}/codeql/csharp ${CODEQL_HOME}/codeql/python ${CODEQL_HOME}/codeql/go ${CODEQL_HOME}/codeql/csv ${CODEQL_HOME}/codeql/xml ${CODEQL_HOME}/codeql/legacy-upgrades && \
    rm -rf ${CODEQL_HOME}/codeql-repo/cpp ${CODEQL_HOME}/codeql-repo/csharp ${CODEQL_HOME}/codeql-repo/python ${CODEQL_HOME}/codeql-repo/go ${CODEQL_HOME}/codeql-repo/csv ${CODEQL_HOME}/codeql-repo/xml ${CODEQL_HOME}/codeql-repo/docs ${CODEQL_HOME}/codeql-repo/javascript/ql/test ${CODEQL_HOME}/codeql-repo/javascript/extractor/tests ${CODEQL_HOME}/codeql-repo/java/ql/test






FROM ubuntu:20.04@sha256:4e4bc990609ed865e07afc8427c30ffdddca5153fd4e82c20d8f0783a291e241

ENV DEBIAN_FRONTEND=noninteractive
ENV CODEQL_HOME /usr/local/codeql-home
ENV PATH="${CODEQL_HOME}/codeql:${PATH}"
ENV PYTHONIOENCODING=utf-8

# hadolint ignore=DL3004,DL4006

# hadolint ignore=SC1072,DL3008,DL3004,DL4006
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends curl sudo && \
    curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash - && \
    apt-get install -y --no-install-recommends \
        curl \
        git \
        openssh-client \
        python3-minimal \
        python3-pip \
        sudo \
        jq \
        discount \
        nodejs \
        maven && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* && \
        ln -s /usr/bin/python3.8 /usr/bin/python && \
        ln -s /usr/bin/pip3 /usr/bin/pip

# install the zscalar ca cert
COPY Zscaler-Root-CA.pem .
# hadolint ignore=DL3013
RUN openssl x509 -inform pem -in Zscaler-Root-CA.pem -out /usr/local/share/ca-certificates/Zscaler-Root-CA.crt \
    && update-ca-certificates \
    && python -m pip config set global.cert /etc/ssl/certs/ca-certificates.crt \
    && python -m pip install --upgrade pip

COPY --from=codeql_base ${CODEQL_HOME} ${CODEQL_HOME}
COPY container /usr/local/startup_scripts/
COPY --from=codeql_base /opt/codeql /opt/codeql

RUN python -m pip install -r /usr/local/startup_scripts/requirements.txt

ENTRYPOINT ["python3", "/usr/local/startup_scripts/startup.py"]
