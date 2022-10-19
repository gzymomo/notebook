@echo off

rem
title   Git Working
cls 

goto selectAll

pause

rem
:selectAll
echo ----------------------------------------
echo    Please Enter 1 or 2£¬Then Enter
echo ----------------------------------------
echo        1£¬Commit all file
echo        2£¬Exit
set/p n=  Please Chose£º

if "%n%"=="1" ( goto all ) else ( if "%n%"=="2" ( exit ) else ( goto selectAll ))

:all
echo waiting pulling...
git pull
echo pull success,wait add local file...
git add .
echo wait commit and push...
git commit -m "study"

Echo 
git push 
goto selectAll