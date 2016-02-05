@echo off
cd /d %~dp0

shift
./node_modules/.bin/gulp.cmd %*
