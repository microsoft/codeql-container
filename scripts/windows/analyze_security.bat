@echo off
setlocal enabledelayedexpansion

set scriptname=%0
set inputfile=%1
set outputfile=%2
set language=%3

set argCount=0
for %%x in (%*) do (
   set /A argCount+=1
   set "argVec[!argCount!]=%%~x"
)

if %argCount% LSS 3 (
    call :print_yellow "Please provide the folder to analyze, the folder to store results, and the coding language of the project" 
    call :print_yellow "Usage: %scriptname% :folder to analyze: :folder to store result: :language:"
    call :print_yellow  "Example: %scriptname% C:\Source\pandas C:\Results python"
exit /b 1
)

call :print_yellow "Getting the image..."
docker pull mcr.microsoft.com/cstsectools/codeql-container
call :print_green "Pulled the container" 

call :print_yellow "Creating the codeQL database. This might take some time depending on the size of the project..."
start /W /B docker run --rm --name codeql-container -v "%inputfile%:/opt/src" -v "%outputfile%:/opt/results" -e CODEQL_CLI_ARGS="database create --language=%language%% /opt/results/source_db -s /opt/src" mcr.microsoft.com/cstsectools/codeql-container

if %errorlevel% GTR 0 (
    call :print_red "Failed creating the database"    
    exit /b %errorlevel%
)

start /W /B docker run --rm --name codeql-container -v "%inputfile%:/opt/src" -v "%outputfile%:/opt/results" -e CODEQL_CLI_ARGS="database upgrade /opt/results/source_db" mcr.microsoft.com/cstsectools/codeql-container 
if %errorlevel% GTR 0 (
    call :print_red "Failed upgrading the database"    
    exit /b %errorlevel%
)

call :print_yellow "Running the Quality and Security rules on the project"
start /W /B docker run --rm --name codeql-container -v "%inputfile%:/opt/src" -v "%outputfile%:/opt/results" -e CODEQL_CLI_ARGS="database analyze /opt/results/source_db --format=sarifv2.1.0 --output=/opt/results/issues.sarif %language%-security-and-quality.qls" mcr.microsoft.com/cstsectools/codeql-container
if %errorlevel% GTR 0 (
    call :print_red "Failed to run the query on the database"    
    exit /b %errorlevel%
)

if %errorlevel% EQU 0 (
    call :print_yellow "The results file are saved at at %2\issues.sarif"
)

:print_yellow
    echo [33m%~1[0m
    exit /b 0

:print_red
    echo [31m%~1[0m
    exit /b 0

:print_green
    echo [32m%~1[0m
    exit /b 0
