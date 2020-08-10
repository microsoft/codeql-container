set scriptname=%0
set inputfile=%1
set outputfile=%2

@echo off
setlocal enabledelayedexpansion

set argCount=0
for %%x in (%*) do (
   set /A argCount+=1
   set "argVec[!argCount!]=%%~x"
)

if %argCount% LSS 2 (
echo "Please provide the folder to analyze, and the folder to store results" 
    echo "Usage: %scriptname% <folder to analyze> <folder to store result>"
exit /b 1
)

rem docker pull codeql/codeql-container
echo docker run --rm --name codeql-container -v "%inputfile%:/opt/src" -v "%outputfile%:/opt/results" -e CODEQL_CLI_ARGS="database create --language=python /opt/src/source_db" csteosstools.azurecr.io/codeql/codeql-container
start /W /B docker run --rm --name codeql-container -v "%inputfile%:/opt/src" -v "%outputfile%:/opt/results" -e CODEQL_CLI_ARGS="database create --language=python /opt/src/source_db" csteosstools.azurecr.io/codeql/codeql-container

call :print_status "Failed creating the database" , %errorlevel%
if %errorlevel% GTR 0 (
    call :print_exit_error "Failed creating the database"    
    exit /b %errorlevel%
)
start /W /B docker run --rm --name codeql-container -v "%inputfile%:/opt/src" -v "%outputfile%:/opt/results" -e CODEQL_CLI_ARGS="database upgrade /opt/src/source_db" csteosstools.azurecr.io/codeql/codeql-container 
if %errorlevel% GTR 0 (
    call :print_exit_error "Failed upgrading the database"    
    exit /b %errorlevel%
)
start /W /B docker run --rm --name codeql-container -v "%inputfile%:/opt/src" -v "%outputfile%:/opt/results" -e CODEQL_CLI_ARGS="database analyze /opt/src/source_db --format=sarifv2 --output=/opt/results/issues.sarif python-security-and-quality.qls" csteosstools.azurecr.io/codeql/codeql-container 
if %errorlevel% GTR 0 (
    call :print_exit_error "Failed to run the query on the database"    
    exit /b %errorlevel%
)
echo "The results file should be located at %2\issues.sarif"


:print_exit_error
    echo.
    echo [7;31m%~1[0m
    echo.
    echo [0mExiting...[0m
