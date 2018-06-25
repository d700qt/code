# escape=`
FROM microsoft/windowsservercore

RUN powershell -Command `
    Add-WindowsFeature Web-Server; 

COPY index.html "C:\\inetpub\\wwwroot\\index.html"

ENTRYPOINT [ "ping", "localhost", "-t"]

EXPOSE 80
