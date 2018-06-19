# escape=`
FROM microsoft/windowsservercore

RUN powershell -Command `
    Add-WindowsFeature Web-Server; 

COPY index.html "C:\\inetpub\\wwwroot\\index.html"

EXPOSE 80