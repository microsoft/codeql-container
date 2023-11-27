FROM ubuntu:22.04 AS codeql_base
LABEL maintainer="Github codeql team"

# tzdata install needs to be non-interactive
ENV DEBIAN_FRONTEND=noninteractive

ARG USERNAME=codeql
ENV CODEQL_HOME /usr/local/codeql-home

# create user, install/update basics and python
RUN adduser --home ${CODEQL_HOME} ${USERNAME} && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    	software-properties-common \
        nodejs \
    	vim \
    	curl \
    	wget \
    	git \
        git-lfs \
    	build-essential \
    	unzip \
    	apt-transport-https \
        python3.10 \
    	python3-venv \
    	python3-pip \
    	python3-setuptools \
        python3-dev \
        python-is-python3 \
    	gnupg \
    	g++ \
    	make \
    	gcc \
    	apt-utils \
        rsync \
    	file \
        dos2unix \
    	gettext && \
        apt-get clean

# Install .NET Core and Java for tools/builds
RUN cd /tmp && \
    wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update; \
    apt-get install -y default-jdk apt-transport-https && \
    apt-get update && \
    rm packages-microsoft-prod.deb
RUN apt-get install -y dotnet-sdk-6.0

# Clone our setup and run scripts
RUN mkdir -p /usr/local/startup_scripts
COPY container /usr/local/startup_scripts/

RUN pip3 install -r /usr/local/startup_scripts/requirements.txt

# Install latest codeQL

# record the latest version of the codeql-cli
RUN python3 /usr/local/startup_scripts/get-latest-codeql-version.py > /tmp/codeql_version
RUN mkdir -p \
    ${CODEQL_HOME}/codeql-repo \
    /opt/codeql

# get the latest codeql queries and record the HEAD
RUN git clone --depth 1 https://github.com/github/codeql ${CODEQL_HOME}/codeql-repo && \
    git --git-dir ${CODEQL_HOME}/codeql-repo/.git log --pretty=reference -1 > /opt/codeql/codeql-repo-last-commit

RUN CODEQL_VERSION=$(cat /tmp/codeql_version) && \
    wget -q https://github.com/github/codeql-cli-binaries/releases/download/${CODEQL_VERSION}/codeql-linux64.zip -O /tmp/codeql_linux.zip && \
    unzip /tmp/codeql_linux.zip -d ${CODEQL_HOME} && \
    rm /tmp/codeql_linux.zip

ENV PATH="${CODEQL_HOME}/codeql:${PATH}"

# Pre-compile our queries to save time later
RUN codeql query compile --threads=0 ${CODEQL_HOME}/codeql-repo/*/ql/src/codeql-suites/*.qls --additional-packs=.

ENV PYTHONIOENCODING=utf-8

# Change ownership of all files and directories within CODEQL_HOME to the codeql user
#RUN chown -R ${USERNAME}:${USERNAME} ${CODEQL_HOME}

USER ${USERNAME}

ENTRYPOINT ["python3", "/usr/local/startup_scripts/startup.py"] 