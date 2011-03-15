echo off
rem IIS applicationhost.config doesn't seem to process enviroment variables, so we cant use one
rem for our service path. A hack, but bust out ruby and manually replace the %SAMPLE_SERVICE_DIR%
rem marker in the virtual directory path. 
ruby setpath.rb
"%ProgramFiles(x86)%\iis express\iisexpress" /config:".\applicationhost.config" 

