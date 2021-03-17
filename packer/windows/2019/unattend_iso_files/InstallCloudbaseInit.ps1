$url = "https://www.cloudbase.it/downloads/CloudbaseInitSetup_Stable_x64.msi"
$file = "$env:temp\CloudbaseInitSetup_Stable_x64.msi"

(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)

$MSIArguments = @(
	"/i"
	$file
	"/qn"
	"/l*v c:\cloudbase-init-install.log"
)

Start-Process msiexec.exe -Wait -ArgumentList $MSIArguments