from sys import exit
from re import search
from zipfile import ZipFile
from libs.utils import *
from logging import getLogger
from libs.github import get_latest_github_repo_version

logger = getLogger('codeql-container')

class CodeQL:
    """
        Codeql related logic, downloading, installing etc
    """
    CODEQL_HOME = None

    CODEQL_GITHUB_URL = 'https://github.com/github/codeql-cli-binaries'
    CODEQL_QUERIES_URL = 'https://github.com/github/codeql'
    CODEQL_GO_QUERIES_URL = 'https://github.com/github/codeql-go'

    TEMP_DIR ='/tmp'

    # Error codes
    ERROR_EXECUTING_CODEQL = 2
    ERROR_UNKNOWN_OS = 3
    ERROR_GIT_COMMAND = 4

    def __init__(self, codeql_base_dir):
        self.CODEQL_HOME = codeql_base_dir

    def download_and_install_latest_codeql(self, github_version):
        """
            Download and install the latest codeql-cli from the github repo releases
        """
        download_url = None
        download_path = None
        if os_name == 'posix':
            download_url = f'https://github.com/github/codeql-cli-binaries/releases/download/{github_version.title}/codeql-linux64.zip'
            download_path = f'{self.TEMP_DIR}/codeql_linux.zip'
        elif os_name == 'nt':
            download_url = f'https://github.com/github/codeql-cli-binaries/releases/download/{github_version.title}/codeql-win64.zip'
            download_path = f'{self.TEMP_DIR}/codeql_windows.zip'
        else:
            exit(self.ERROR_UNKNOWN_OS)

        logger.info(f'Downloading codeql-cli version {github_version.title}...')
        check_output_wrapper(f"wget -q {download_url} -O {download_path}", shell=True).decode("utf-8")
        self.install_codeql_cli(download_path)
        #rm /tmp/codeql_linux.zip

    def download_and_install_latest_codeql_queries(self):
        """
            Download and install the latest codeql queries from the github repo
        """
        logger.info("Downloading codeql queries...")
        codeql_repo_dir = f'{self.CODEQL_HOME}/codeql-repo'
        wipe_and_create_dir(codeql_repo_dir)
        ret1 = check_output_wrapper(f'git clone {self.CODEQL_QUERIES_URL} {codeql_repo_dir}', shell=True)

        codeql_go_repo_dir = f'{self.CODEQL_HOME}/codeql-go-repo'
        wipe_and_create_dir(codeql_go_repo_dir)
        ret2 = check_output_wrapper(f'git clone {self.CODEQL_GO_QUERIES_URL} {codeql_go_repo_dir}', shell=True)
        if ret1 is CalledProcessError or ret2 is CalledProcessError:
            logger.error("Could not run git command")
            exit(self.ERROR_GIT_COMMAND)

    def get_current_local_version(self):
        ret_string = check_output_wrapper(f'{self.CODEQL_HOME}/codeql/codeql version', shell=True).decode("utf-8")
        if ret_string is CalledProcessError:
            logger.error("Could not run codeql command")
            exit(self.ERROR_EXECUTING_CODEQL)
            
        version_match = search("toolchain release ([0-9.]+)\.", ret_string)
        if not version_match:
            logger.error("Could not determine existing codeql version")
            exit(self.ERROR_EXECUTING_CODEQL)
        version = f'v{version_match.group(1)}'
        return version

    def get_latest_codeql_github_version(self):
        return get_latest_github_repo_version("github/codeql-cli-binaries")

    def install_codeql_cli(self, download_path):
        logger.info("Installing codeql-cli...")
        codeql_dir = f'{self.CODEQL_HOME}/codeql'
        wipe_and_create_dir(codeql_dir)
        ret1 = check_output_wrapper(f'unzip {download_path} -d {codeql_dir}', shell=True)
        
    def precompile_queries(self):
        self.execute_codeql_command(f' query compile --search-path {self.CODEQL_HOME} {self.CODEQL_HOME}/codeql-repo/*/ql/src/codeql-suites/*.qls')

    def execute_codeql_command(self, args):
        ret_string = check_output_wrapper(f'{self.CODEQL_HOME}/codeql/codeql {args}', shell=True)
        if ret_string is CalledProcessError:
            logger.error("Could not run codeql command")
            exit(self.ERROR_EXECUTING_CODEQL)
        return bytearray(ret_string).decode('utf-8')
