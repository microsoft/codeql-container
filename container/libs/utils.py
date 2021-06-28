import sys
from shutil import rmtree
from os import environ, mkdir, name as os_name
from subprocess import check_output, CalledProcessError
from logging import Logger, getLogger, INFO, StreamHandler, Formatter

logger = getLogger('codeql-container')
ERROR_EXECUTING_COMMAND = 1

# get secrets from the env
def get_env_variable(var_name, optional=False):
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
        logger.error(f"Error {msg.returncode} executing from command.")
        if msg.stderr != None:
            print("Command Error Output:\n" + msg.stderr.decode('utf-8'))
        if msg.output != None:
            print("Command Output: \n" + msg.output.decode('utf-8'))
        logger.error("Exiting...")
        sys.exit(ERROR_EXECUTING_COMMAND);
        
def wipe_and_create_dir(dirname):
    rmtree(dirname, True)
    mkdir(dirname)

def get_logger(log_level=INFO):
    try:
        logger = getLogger(sys._getframe(1).f_code.co_name)
        logger.setLevel(log_level)
        if not logger.handlers:
            log_handler = StreamHandler(sys.stdout)
            log_handler.setLevel(log_level)
            log_handler.setFormatter(Formatter('[%(asctime)s] %(levelname)s: %(message)s'))

            logger = getLogger(sys._getframe(1).f_code.co_name)
            logger.addHandler(log_handler)
        return logger
    except Exception as ex:
        print(str(ex))