@echo off
setlocal

rem GitHub project sites need the repository path, for example /portfolio/.
rem For a custom domain or a user GitHub Pages site, use /.
set BASE_HREF=%~1
if "%BASE_HREF%"=="" set BASE_HREF=/

C:\flutter\bin\flutter.bat pub get
if errorlevel 1 exit /b %errorlevel%

C:\flutter\bin\flutter.bat build web --release --base-href %BASE_HREF%
