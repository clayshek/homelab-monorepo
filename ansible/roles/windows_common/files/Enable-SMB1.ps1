if ((Get-WindowsOptionalFeature -Online -FeatureName smb1protocol).State -eq "Enabled") {

 } else {
	Enable-WindowsOptionalFeature -Online -FeatureName smb1protocol
}
