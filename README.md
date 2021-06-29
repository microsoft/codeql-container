## CodeQL Container

> **Note:** CodeQL container is currently in **public preview**. Please report any bugs to https://github.com/microsoft/codeql-container/issues.
> Current version of CodeQL only works for interpreted languages. We will add compiled languages support in future versions.

The CodeQL Container is a project aimed at making it easier to start using CodeQL (more about codeQL at https://github.com/github/codeql). This project
contains a Docker file which builds a container with the latest version of codeql-cli, and the latest codeql queries precompiled. 
It also contains automation to keep the toolchain in the container updated. You can use this container to:

* Start using codeql-cli and run queries on your projects without installing it on your local machine.
* Use it as an environment to develop codeql queries and test them.
* Test how the queries perform in windows and linux environments (and more...)

We shall continue to add more features and would be happy to accept contributions from the community.

### TL;DR

Analyze the python project django located in the folder ```/tmp/django``` by running the security and quality QL pack on it:

```
/scripts/unix/analyze_security.sh /tmp/django/src /tmp/django/results python
```

The results will be stored in /tmp/django/results/issues.sarif.

Analyze the Javascript project express located in /tmp/express/src by running the extended security QL pack on it:
```
scripts/unix/run_qlpack.sh /tmp/express/src /tmp/express/results javascript security-extended
```

The results will be stored in /tmp/express/results/issues.sarif

To find a list of QL packs installed in the container:

```
docker run --rm --name codeql-container -e CODEQL_CLI_ARGS="resolve qlpacks"  mcr.microsoft.com/cstsectools/codeql-container
```

### Downloading a pre-built container

We keep updating the docker image periodically and uploading it to the Microsoft Container Registry at: ```mcr.microsoft.com/cstsectools/codeql-container```.

You can pull the image by running the command:
```
$ docker pull mcr.microsoft.com/cstsectools/codeql-container
```


### Building the container from Dockerfile

Building the container should be pretty straightforward.

```
git clone https://github.com/microsoft/codeql-container
cd codeql-container
docker build . -f Dockerfile -t codeql-container
```

### Basic Usage
 
The codeQL container executes one codeQL command per invocation. We designed it this way because it makes it easy for the user to run any codeQL command, and not be bound by the automation scripts inside the container.

The basic example format of the container invocation is as follows:

```
$ docker run --rm --name codeql-container -v /dir/to/analyze:/opt/src -v /dir/for/results:/opt/results -e CODEQL_CLI_ARGS=<query run...> mcr.microsoft.com/cstsectools/codeql-container
```

where `/dir/to/analyze` contains the source files that have to be analyzed, and `/dir/for/results` is where the result output 
needs to be stored, and you can specify CODEQL_CLI_ARGS environment variable for specific QL packs to be run on the provided code, among other things. The CODEQL_CLI_ARGS will be passed over to codeQL command line as it is.

For more information on CodeQL and QL packs, please visit https://www.github.com/github/codeql.

`CODEQL_CLI_ARGS` are the arguments that will be directly passed on to the codeql-cli. For example, in this case, if we supply:

```
CODEQL_CLI_ARGS="database create /opt/results/source_db -s /opt/src"
```

it will create a codeQL db of your project (in ```/dir/to/analyze``` ) in the ```/dir/for/results``` folder.

> **Note:** If you map your source volume to some other mount point other than /opt/src, you will have to make the corresponding changes
> in the `CODEQL_CLI_ARGS`.

There are some additional docker environment flags that you can set/unset to control the execution of the container:

* `CHECK_LATEST_CODEQL_CLI` - If there is a newer version of codeql-cli, download and install it
* `CHECK_LATEST_QUERIES` - if there is are updates to the codeql queries repo, download and use it
* `PRECOMPILE_QUERIES` - If we downloaded new queries, precompile all new query packs (query execution will be faster)

> **WARNING:** Precompiling query packs might take a few hours, depending on speed of your machine and the CPU/memory limits (if any)
> you have placed on the container.

Since CodeQL first creates a database of the code representation, and then analyzes the said database for issues, we need to invoke the container more than once to analyze a source code repo. (Since the container only executes one codeQL command per invocation.)

For example, if you want to analyze a python project source code placed in `/dir/to/analyze` (or `C:\dir\to\analyze` for example, in Windows), 
to analyze and get a SARIF result file, you will have to run:

```
# create the codeql db
$ export language="python"
$ docker run --rm --name codeql-container -v /dir/to/analyze:/opt/src -v /dir/for/results:/opt/results -e CODEQL_CLI_ARGS="database create --language=${language} /opt/results/source_db -s /opt/src" mcr.microsoft.com/cstsectools/codeql-container

# upgrade the db if necessary
$ docker run --rm --name codeql-container -v /dir/to/analyze:/opt/src -v /dir/for/results:/opt/results -e CODEQL_CLI_ARGS=" database upgrade /opt/results/source_db" mcr.microsoft.com/cstsectools/codeql-container

# run the queries in the qlpack
$ docker run --rm --name codeql-container -v /dir/to/analyze:/opt/src -v /dir/for/results:/opt/results -e CODEQL_CLI_ARGS="database analyze --format=sarifv2 --output=/opt/results/issues.sarif /opt/results/source_db ${language}-security-and-quality.qls" mcr.microsoft.com/cstsectools/codeql-container
```

For more information on CodeQL and QL packs, please visit https://www.github.com/github/codeql.

### Convenience Scripts
Analyzing a source directory takes multiple invocations of the container, as mentioned above. To help with that, we've built some scripts for convenience, which does these invocations for you. 
These scripts are in the ```scripts``` folder, under their respective platforms (unix or windows).

#### analyze_security.sh
scripts/unix/analyze_security.sh (or scripts/windows/analyze_security.bat for windows) runs the Security and Quality QL pack suite on your project. This is how you would run it:

```
scripts/unix/analyze_security.sh /path/to/analyze /path/to/results language
```

For example for the python project can be analyzed thus:

```
/scripts/unix/analyze_security.sh /tmp/django/src /tmp/django/output python
```

for JavaScript:
```
/scripts/unix/analyze_security.sh /tmp/express/src /tmp/express/output javascript
```

#### run_qlpack.sh
If you know which QL suite you would like to run on the code, use scripts/unix/run_qlpack.sh (or scripts/windows/run_qlpack.bat for windows). 

```
scripts/unix/run_qlpack.sh /path/to/analyze /path/to/results language qlpack
```

For example, on windows:

```
scripts\windows\run_ql_suite.bat e:\temp\express\src e:\temp\express\results javascript code-scanning 
```

### Contributing

This project welcomes contributions and suggestions. Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
