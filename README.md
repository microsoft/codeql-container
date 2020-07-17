## CodeQL Container

> **Note:** CodeQL container is currently in **public preview**. Please report any bugs to https://github.com/microsoft/codeql-container/issues.
> Current version of CodeQL only works for interpreted languages. We will add compiled languages support on future versions.

CodeQL Container is a project aimed at making it easier to start using CodeQL (https://github.com/github/codeql). This project
contains a Docker file which builds a container, with the latest version of codeql-cli and codeql queries precompiled. 
It also contains scripts to keep the toolchain in the container updated. You can use this container to:

* Start using codeql-cli and run queries on your projects without installing it on your local machine.
* Use is as an environment to develop codeql queries and test them.
* Test how the queries perform in windows and linux environments.

We shall continue to add more features and would be happy to accept contributions from the community.

### Basic Usage

#### Downloading a pre-built container

We keep updating the docker image periodically and uploading it to the Microsoft Container Registry at: mcr.microsoft.com/codeql/codeql-container.

You can pull the image by running the command:
```
$ docker pull mcr.microsoft.com/codeql/codeql-container
```

If you want to analyze a particular source directory with codeql, run the container as:

```
$ docker run --rm --name codeql-container mcr.microsoft.com/codeql/codeql-container -v /dir/to/analyze:/opt/src -v /dir/for/results:/opt/results -e CODEQL_CLI_ARGS=<query run...>
```

where `/dir/to/analyze` contains the source files that have to be analyzed, and `/dir/for/results` is where the result output 
needs to be stored, and you can specify QL_PACKS environment variable for specific QL packs to be run on the provided code.
For more information on CodeQL and QL packs, please visit https://www.github.com/github/codeql.

`CODEQL_CLI_ARGS` are the arguments that will be directly passed on to the codeql-cli. Some examples of `CODEQL_CLI_ARGS` are:

```
CODEQL_CLI_ARGS="database create /opt/src/source_db"
```

**Note:** If you map your source volume to some other mountpoint other than /opt/src, you will have to make the corresponding changes
in the `CODEQL_CLI_ARGS`.

There are some additional docker environment variables that you can specify to control the execution of the container:

* `CHECK_LATEST_CODEQL_CLI` - If there is a newer version of codeql-cli, download and install it
* `CHECK_LATEST_QUERIES` - if there is are updates to the codeql queries repo, download and use it
* `PRECOMPILE_QUERIES` - If we downloaded new queries, precompile all new query packs (query execution will be faster)

**WARNING:** Precompiling query packs might take a few hours, depending on speed of your machine and the CPU/memory limits (if any)
you have placed on the container.

Since CodeQL first creates a database of the code representation, and then analyzes the db for issues, we need a few commands to 
analyze a source code repo.

For example, if you want to analyze a python project source code placed in `/dir/to/analyze` (or `C:\dir\to\analyze` for example, in Windows), 
to analyze and get a SARIF result file, you will have to run:

```
$ docker run --rm --name codeql-container mcr.microsoft.com/codeql/codeql-container -v /dir/to/analyze:/opt/src -v /dir/for/results:/opt/results -e CODEQL_CLI_ARGS="database create --language=python /opt/src/source_db"
$ docker run --rm --name codeql-container mcr.microsoft.com/codeql/codeql-container -v /dir/to/analyze:/opt/src -v /dir/for/results:/opt/results -e CODEQL_CLI_ARGS=" database upgrade /opt/src/source_db"
$ docker run --rm --name codeql-container mcr.microsoft.com/codeql/codeql-container -v /dir/to/analyze:/opt/src -v /dir/for/results:/opt/results -e CODEQL_CLI_ARGS="database analyze --format=sarifv2 --output=/opt/results/issues.sarif /opt/src/source_db"
```

For more information on CodeQL and QL packs, please visit https://www.github.com/github/codeql.

#### Building the container

Building the container should be pretty straightforward.

```
git clone https://github.com/microsoft/codeql-container
cd codeql-container
docker build . -f Dockerfile -t codeql-container
```

# Contributing

This project welcomes contributions and suggestions. Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
