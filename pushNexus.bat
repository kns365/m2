@echo off
setlocal enabledelayedexpansion

:: 1. Cấu hình
set "REPO_PATH=D:\work\app\package\m2\repository"
set "NEXUS_URL=http://10.12.0.10:8085/repository/maven-releases/"
set "REPOSITORY_ID=nexus-repo"
set "TEMP_DIR=C:\temp_deploy"
:: File log sẽ nằm cùng thư mục với file bat này
set "LOG_FILE=%~dp0deploy_history.log"

if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
:: Khởi tạo file log nếu chưa có
if not exist "%LOG_FILE%" (
    echo ### KHOI TAO LOG DEPLOY ### > "%LOG_FILE%"
)

echo Dang quet va day hang len Nexus...
echo Luu y: Kiem tra file log tai: %LOG_FILE%
echo ----------------------------------------------------

for /r "%REPO_PATH%" %%f in (*.pom) do (
    set "POM_FILE=%%f"
    set "JAR_FILE=%%~dpnf.jar"
    set "FILENAME=%%~nxf"

    :: Kiểm tra file log - GIỮ NGUYÊN LOGIC CŨ CỦA BẠN
    findstr /c:"!FILENAME!" "%LOG_FILE%" >nul
    if !errorlevel! equ 0 (
        echo [SKIPPED] !FILENAME! da ton tai.
    ) else (
        echo [*] Dang xu ly: !FILENAME!
        copy /y "!POM_FILE!" "%TEMP_DIR%\temp.pom" >nul
        
        if exist "!JAR_FILE!" (
            copy /y "!JAR_FILE!" "%TEMP_DIR%\temp.jar" >nul
            :: THÊM THAM SỐ BỔ TRỢ ĐỂ NHẬN DIỆN REPO ID CHÍNH XÁC
            call mvn org.apache.maven.plugins:maven-deploy-plugin:3.1.1:deploy-file ^
                -Dfile="%TEMP_DIR%\temp.jar" -DpomFile="%TEMP_DIR%\temp.pom" ^
                -DrepositoryId=%REPOSITORY_ID% -Durl=%NEXUS_URL% -DgeneratePom=false
        ) else (
            call mvn org.apache.maven.plugins:maven-deploy-plugin:3.1.1:deploy-file ^
                -Dfile="%TEMP_DIR%\temp.pom" -DpomFile="%TEMP_DIR%\temp.pom" ^
                -DrepositoryId=%REPOSITORY_ID% -Durl=%NEXUS_URL% -DgeneratePom=false
        )

        :: Ghi log bất kể thành công hay thất bại để bạn theo dõi
        if !errorlevel! equ 0 (
            echo [SUCCESS] !FILENAME! !date! !time! >> "%LOG_FILE%"
        ) else (
            echo [FAILED] !FILENAME! - Vui long kiem tra settings.xml >> "%LOG_FILE%"
            echo ERROR: Maven khong the upload !FILENAME!.
        )
    )
)

echo ----------------------------------------------------
echo Dang don dep...
rd /s /q "%TEMP_DIR%"
echo === XONG ROI BO HILO OI! ===
pause