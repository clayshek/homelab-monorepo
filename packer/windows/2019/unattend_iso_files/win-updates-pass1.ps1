Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name PSWindowsUpdate -Force
Get-WindowsUpdate -Install -AcceptAll -IgnoreUserInput -AutoReboot | Out-File c:\win-updates.log -append