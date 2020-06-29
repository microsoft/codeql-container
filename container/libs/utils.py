from sys import exit
from shutil import rmtree
from os import environ, mkdir, name as os_name
from subprocess import check_output, CalledProcessError
from logging import getLogger

logger = getLogger('codeql-container')

# get secrets from the env
def get_env_variable(self, var_name, optional=False):
    """
    Retrieve an environment variable. Any failures will cause an exception
    to be thrown.
    """
    try:
        return environ[var_name]
    except KeyError:
        if optional:
            return False
        else:
            error_msg = f'Error: You must set the {var_name} environment variable.'
            raise Exception(error_msg)

def check_output_wrapper(*args, **kwargs):
    """
        Thin wrapper around subprocess
    """

    logger.debug('Executing %s, %s', args, kwargs)
    try:
        return check_output(*args, **kwargs)
    except CalledProcessError as msg:
        logger.warning('Error %s,%s,%s from command.', msg.returncode, msg.output, msg.stderr)
        logger.debug('Output: %s', msg.output)
        sys.exit(ERROR_EXECUTING_COMMAND);
        
def wipe_and_create_dir(dirname):
    rmtree(dirname)
    mkdir(dirname)
