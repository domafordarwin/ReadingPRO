@echo off
REM pgweb PostgreSQL Web UI Connection Script for Windows
REM Supports both local development and Railway production environments

echo 🔗 PGWeb Connection Helper
echo ==========================
echo.

REM Check if DATABASE_URL is set
if "%DATABASE_URL%"=="" (
    echo ❌ DATABASE_URL not set
    echo.
    echo 📝 For Local Development:
    echo    Set DATABASE_URL environment variable:
    echo    set DATABASE_URL=postgres://postgres:password@localhost:5432/reading_pro_development
    echo.
    echo    OR run with inline:
    echo    set DATABASE_URL=postgres://user:password@localhost:5432/dbname
    echo    pgweb
    echo.
    echo 📝 For Railway Production:
    echo    Get DATABASE_URL from Railway:
    echo    railway link
    echo    Then set environment variable and run pgweb
    echo.
    exit /b 1
)

echo ✅ DATABASE_URL found
echo.

REM Check if pgweb is installed
where pgweb >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo 🚀 Starting pgweb with:
    echo    URL: %DATABASE_URL%
    echo.
    echo    Web UI will be available at: http://localhost:8081
    echo.
    pgweb --url "%DATABASE_URL%"
) else (
    echo ❌ pgweb not installed
    echo.
    echo 📦 Installation:
    echo    Windows (using Scoop):
    echo      scoop install pgweb
    echo.
    echo    Or download from:
    echo      https://sosedoff.com/pgweb/
    echo.
)

pause
