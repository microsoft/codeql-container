FROM ubuntu:20.04 AS codeql_base
LABEL maintainer="Github codeql team"

# tzdata install needs to be non-interactive
ENV DEBIAN_FRONTEND=noninteractive

# install/update basics and python
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    	software-properties-common \
    	vim \
    	curl \
    	wget \
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
    	gettext && \
        apt-get clean && \
        rm -f /usr/bin/python /usr/bin/pip && \
        ln -s /usr/bin/python3.8 /usr/bin/python && \
        ln -s /usr/bin/pip3 /usr/bin/pip 

# Install .NET Core and Java for tools/builds
RUN cd /tmp && \
    wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update; \
    apt-get install -y default-jdk apt-transport-https && \
    apt-get update && \
    rm packages-microsoft-prod.deb
RUN apt-get install -y dotnet-sdk-3.1

# Clone our setup and run scripts
#RUN git clone https://github.com/microsoft/codeql-container /usr/local/startup_scripts
RUN mkdir -p /usr/local/startup_scripts
RUN ls -al /usr/local/startup_scripts
COPY container /usr/local/startup_scripts/
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
RUN git clone --depth 1 https://github.com/github/codeql ${CODEQL_HOME}/codeql-repo && \
    git --git-dir ${CODEQL_HOME}/codeql-repo/.git log --pretty=reference -1 > /opt/codeql/codeql-repo-last-commit
RUN git clone --depth 1 https://github.com/github/codeql-go ${CODEQL_HOME}/codeql-go-repo && \
    git --git-dir ${CODEQL_HOME}/codeql-go-repo/.git log --pretty=reference -1 > /opt/codeql/codeql-go-repo-last-commit

RUN CODEQL_VERSION=$(cat /tmp/codeql_version) && \
    wget -q https://github.com/github/codeql-cli-binaries/releases/download/${CODEQL_VERSION}/codeql-linux64.zip -O /tmp/codeql_linux.zip && \
    unzip /tmp/codeql_linux.zip -d ${CODEQL_HOME} && \
    rm /tmp/codeql_linux.zip

ENV PATH="${CODEQL_HOME}/codeql:${PATH}"

# Pre-compile our queries to save time later
RUN codeql query compile --threads=0 ${CODEQL_HOME}/codeql-repo/*/ql/src/codeql-suites/*.qls --additional-packs=.
RUN codeql query compile --threads=0 ${CODEQL_HOME}/codeql-go-repo/ql/src/codeql-suites/*.qls --additional-packs=.

ENV PYTHONIOENCODING=utf-8
ENTRYPOINT ["python3", "/usr/local/startup_scripts/startup.py"]
