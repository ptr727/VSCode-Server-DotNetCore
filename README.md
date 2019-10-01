# Code-Server VSCode with .NET Core SDK and PowerShell Pre-Installed
Image is based on LinuxServer.io Code-Server: https://github.com/linuxserver/docker-code-server
Which is based on Coder.com Code-Server: https://github.com/cdr/code-server
DotNet Core 3 SDK is preinstalled, allowing C# development in Linux.

# Background Info
https://github.com/dotnet/dotnet-docker/blob/master/3.0/sdk/bionic/amd64/Dockerfile
https://github.com/linuxserver/docker-code-server/blob/master/Dockerfile
https://github.com/cdr/code-server/blob/master/Dockerfile
https://forums.unraid.net/topic/81306-support-linuxserverio-code-server/
https://blog.linuxserver.io/2019/09/14/customizing-our-containers/
https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-install-script
https://dotnet.microsoft.com/download/linux-package-manager/ubuntu18-04/sdk-current
https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7

# Notes
- codercom/code-server runs as root.
- linuxserver/code-server allows specifying PUID and GUID, ideal woth UnRaid.
- Use "cat /etc/*-release" to determine the base image, installed packages must match the base image.
- Run DotNet Core by "dotnet" in the console.
- Run PowerShell by "pwsh" in the console.
- If installing PowerShell Core Preview use powershell-preview and pwsh-preview to launch.

# TODO
- Create a container or a dynamic overlay: https://blog.linuxserver.io/2019/09/14/customizing-our-containers/