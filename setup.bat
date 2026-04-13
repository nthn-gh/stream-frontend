@echo off
echo ================================
echo STREAM Setup - Creating Directories
echo ================================
echo.

cd /d c:\Users\Ethan\stream\stream-frontend

echo Creating directories...
mkdir src\components\ui 2>nul
mkdir src\components\features 2>nul
mkdir src\components\navigation 2>nul
mkdir src\views\mobile 2>nul
mkdir src\views\web 2>nul
mkdir src\lib 2>nul

echo.
echo Copying existing components...
copy /Y ..\Button.vue src\components\ui\Button.vue 2>nul
copy /Y ..\Input.vue src\components\ui\Input.vue 2>nul
copy /Y ..\Card.vue src\components\ui\Card.vue 2>nul
copy /Y ..\Badge.vue src\components\ui\Badge.vue 2>nul

echo.
echo Copying configuration...
copy /Y ..\GLOBAL_STYLES.css src\main.css 2>nul

echo.
echo ================================
echo Setup Complete!
echo ================================
echo.
echo Next: The assistant will create component files
pause
