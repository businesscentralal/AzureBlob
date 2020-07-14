cd $PSScriptRoot

. ".\Initialize.ps1"

$containername = "$($settings.name)-dev"
$name = Read-Host -Prompt "Enter name of container (enter for $containerName)"
if ($name) {
    $containername = $name
}

$azureVM = $userProfile.AzureVM
$securePassword = try { ($azureVM.Password | ConvertTo-SecureString) } catch { ($azureVM.Password | ConvertTo-SecureString -AsPlainText -Force) }
$azureVmCredential = New-Object PSCredential $azureVM.Username, $securePassword
$sessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck
$vmSession = $null
$tempLicenseFile = ""
$vmFolder = ""

try {
    $vmSession = New-PSSession -ComputerName $azureVM.ComputerName -Credential $azureVmCredential -UseSSL -SessionOption $sessionOption
    $vmFolder = CopyFoldersToSession -session $vmSession -baseFolder $ProjectRoot -subFolders @("scripts")

    $tempLicenseFile = CopyFileToSession -session $vmSession -localFile $licenseFile -returnSecurestring

    Invoke-Command -Session $vmSession -ScriptBlock { Param($ProjectRoot, $containerName, $imageVersion, $credential, $licenseFile, $settings)
        $ErrorActionPreference = "Stop"
        cd (Join-Path $ProjectRoot "scripts")

        $buildEnv = "AzureVM"
        
        . ".\Install-NavContainerHelper.ps1" `
            -buildEnv $buildEnv `
            -navContainerHelperPath $navContainerHelperPath

        . ".\Create-Container.ps1" `
            -buildEnv $buildEnv `
            -containerName $containerName `
            -artifact $imageversion.artifact `
            -imageName $imageversion.imageName `
            -credential $credential `
            -licensefile $licensefile

    } -ArgumentList $vmFolder, $containerName, $imageVersion, $credential, $tempLicenseFile, $settings

}
catch [System.Management.Automation.Remoting.PSRemotingTransportException] {
    try { $myip = ""; $myip = (Invoke-WebRequest -Uri http://ifconfig.me/ip).Content } catch { }
    throw "Could not connect to $($azureVM.ComputerName). Maybe port 5986 (WinRM) is not open for your IP address $myip"
}
finally {
    if ($vmSession) {
        if ($tempLicenseFile) {
            try { RemoveFileFromSession -session $vmSession -filename $tempLicenseFile } catch {}
        }
        if ($vmFolder) {
            try { RemoveFolderFromSession -session $vmSession -foldername $vmFolder } catch {}
        }
        Remove-PSSession -Session $vmSession
    }
}

UpdateLaunchJson -name "AzureVM Sandbox $containername" -server "https://$($azureVM.ComputerName)" -port 443 -serverInstance "$($containername)dev"
