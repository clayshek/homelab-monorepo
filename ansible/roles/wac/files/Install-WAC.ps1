# Install WAC

Write-Output "$(Get-Date)" | Out-File "c:\windows\temp\Install-WAC.log" -append
Write-Output "Starting Install-WAC.ps1." | Out-File "c:\windows\temp\Install-WAC.log" -append

# Download Windows Admin Center if not present
if (-not (Test-Path -Path "c:\windows\temp\WindowsAdminCenter.msi")){
    Write-Output "Downloading WindowsAdminCenter.msi" | Out-File "c:\windows\temp\Install-WAC.log" -append
    Invoke-WebRequest -UseBasicParsing -Uri https://aka.ms/WACDownload -OutFile "c:\windows\temp\WindowsAdminCenter.msi"
}


# Install Windows Admin Center with self-signed cert. Delay WINRM Restart to not interrupt Ansible.
$alreadyInstalled = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -eq "Windows Admin Center" })

If(-Not $alreadyInstalled) {
    Write-Output "Running WAC setup." | Out-File "c:\windows\temp\Install-WAC.log" -append
	Start-Process msiexec.exe -Wait -ArgumentList "/i c:\windows\temp\WindowsAdminCenter.msi /qn /L*v wac-log.txt REGISTRY_REDIRECT_PORT_80=1 SME_PORT=443 SSL_CERTIFICATE_OPTION=generate RESTART_WINRM=0";
} else {
    Write-Output "WAC found already installed, no further action on install job taken." | Out-File "c:\windows\temp\Install-WAC.log" -append
}

Write-Output "Install-WAC.ps1 Done." | Out-File "c:\windows\temp\Install-WAC.log" -append
Write-Output "$(Get-Date)" | Out-File "c:\windows\temp\Install-WAC.log" -append
