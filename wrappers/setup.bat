@echo off
setlocal enabledelayedexpansion
if "%~1"=="" (
  echo Usage: setup.bat ^<repo-name^> [--profile base^|web^|ds^|lib^|fastapi^|flask^|flask-nginx] [--org owner] [--template-owner owner] [--public] [--no-push] [--ref tag^|branch^|sha]
  exit /b 1
)
set "REPO=%~1"
set "PROFILE=base"
set "ORG=%BOOTSTRAP_ORG%"
set "TEMPLATE_OWNER=%BOOTSTRAP_TEMPLATE_OWNER%"
set "VIS=--private"
set "NO_PUSH="
set "REF="
if not defined BOOTSTRAP_BRANCH (set "BRANCH=main") else (set "BRANCH=%BOOTSTRAP_BRANCH%")
echo %REPO%| findstr /r "^[A-Za-z0-9._-][A-Za-z0-9._-]*$" >nul
if errorlevel 1 ( echo [ERROR] Invalid repo name: %REPO% & exit /b 1 )
:parse
shift
if "%~1"=="" goto run
if /I "%~1"=="--profile" (set "PROFILE=%~2" & shift & goto parse)
if /I "%~1"=="--org" (set "ORG=%~2" & shift & goto parse)
if /I "%~1"=="--template-owner" (set "TEMPLATE_OWNER=%~2" & shift & goto parse)
if /I "%~1"=="--public" (set "VIS=--public" & shift & goto parse)
if /I "%~1"=="--no-push" (set "NO_PUSH=1" & shift & goto parse)
if /I "%~1"=="--ref" (set "REF=%~2" & shift & goto parse)
goto parse
:run
if exist "%REPO%" ( echo [ERROR] Target path "%REPO%" already exists. & exit /b 1 )
if "%TEMPLATE_OWNER%"=="" set "TEMPLATE_OWNER=%ORG%"
where gh >nul 2>nul
if not errorlevel 1 if "%REF%"=="" if not "%TEMPLATE_OWNER%"=="" (
  set "CREATE_ARG=%REPO%"
  if not "%ORG%"=="" set "CREATE_ARG=%ORG%/%REPO%"
  echo [INFO] Using gh to create %CREATE_ARG% from %TEMPLATE_OWNER%/template-%PROFILE% ...
  gh repo create "%CREATE_ARG%" %VIS% --template "%TEMPLATE_OWNER%/template-%PROFILE%" --clone
  if not errorlevel 1 ( cd "%REPO%" & echo [OK] Bootstrapped via GitHub template. & goto done ) else ( echo [WARN] gh template create failed. Falling back. )
)
set "TPL_URL=https://github.com/%TEMPLATE_OWNER%/template-%PROFILE%.git"
echo [INFO] Cloning template: %TPL_URL%
if not "%REF%"=="" (
  git clone --depth 1 -b "%REF%" "%TPL_URL%" "%REPO%"
  if errorlevel 1 ( git clone "%TPL_URL%" "%REPO%" & cd "%REPO%" & git checkout "%REF%" ) else ( cd "%REPO%" )
) else (
  git clone "%TPL_URL%" "%REPO%" & cd "%REPO%"
)
rmdir /s /q .git 2>nul
git init -b "%BRANCH%" 2>nul || (git init & git checkout -b "%BRANCH%")
git add .
if "%REF%"=="" ( git commit -m "chore: bootstrap from template-%PROFILE%" ) else ( git commit -m "chore: bootstrap from template-%PROFILE% @ %REF%" )
if "%NO_PUSH%"=="" (
  where gh >nul 2>nul
  if not errorlevel 1 (
    set "TARGET=%REPO%"
    if not "%ORG%"=="" set "TARGET=%ORG%/%REPO%"
    gh repo create "%TARGET%" %VIS% --source=. --push
  ) else (
    if not "%ORG%"=="" ( git remote add origin "https://github.com/%ORG%/%REPO%.git" & git push -u origin "%BRANCH%" ) else ( echo [INFO] No gh and no --org; leaving repo local only. )
  )
)
:done
echo [OK] Bootstrapped %REPO% from template-%PROFILE% on branch "%BRANCH%".
endlocal
