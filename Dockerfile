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
    	gettext && \
        apt-get clean

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
${CODEQL_HOME}/codeql-cli \
${CODEQL_HOME}/codeql-repo \
${CODEQL_HOME}/codeql-go-repo \
/opt/codeql

RUN CODEQL_VERSION=$(cat /tmp/codeql_version) && \
    wget -q https://github.com/github/codeql-cli-binaries/releases/download/${CODEQL_VERSION}/codeql-linux64.zip -O /tmp/codeql_linux.zip && \
    unzip /tmp/codeql_linux.zip -d ${CODEQL_HOME}/codeql-cli && \
    rm /tmp/codeql_linux.zip

# get the latest codeql queries and record the HEAD
RUN git clone https://github.com/github/codeql ${CODEQL_HOME}/codeql-repo && \
    git --git-dir ${CODEQL_HOME}/codeql-repo/.git log --pretty=reference -1 > /opt/codeql/codeql-repo-last-commit
RUN git clone https://github.com/github/codeql-go ${CODEQL_HOME}/codeql-go-repo && \
    git --git-dir ${CODEQL_HOME}/codeql-go-repo/.git log --pretty=reference -1 > /opt/codeql/codeql-go-repo-last-commit

ENV PATH="${CODEQL_HOME}/codeql-cli/codeql:${PATH}"

# Pre-compile our queries to save time later
#RUN codeql query compile --threads=0 ${CODEQL_HOME}/codelq-repo/*/ql/src/codeql-suites/*-.qls
#RUN codeql query compile --threads=0 ${CODEQL_HOME}/codelq-go-repo/ql/src/codeql-suites/*-.qls
#ENTRYPOINT ["python3", "/usr/local/startup_scripts/setup.py"]