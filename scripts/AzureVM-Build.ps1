cd $PSScriptRoot

. ".\Initialize.ps1"

$containername = "$($settings.name)-bld"

$buildArtifactFolder = Join-Path $ProjectRoot ".output"
if (Test-Path $buildArtifactFolder) { Remove-Item $buildArtifactFolder -Force -Recurse }
New-Item -Path $buildArtifactFolder -ItemType Directory -Force | Out-Null

$azureVM = $userProfile.AzureVM
$securePassword = try { ($azureVM.Password | ConvertTo-SecureString) } catch { ($azureVM.Password | ConvertTo-SecureString -AsPlainText -Force) }
$azureVmCredential = New-Object PSCredential $azureVM.Username, $securePassword
$sessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck
$vmSession = $null
$tempLicenseFile = ""
$tempCodeSignPfxFile = ""
$vmFolder = ""

try {
    $vmSession = New-PSSession -ComputerName $azureVM.ComputerName -Credential $azureVmCredential -UseSSL -SessionOption $sessionOption
    $vmFolder = CopyFoldersToSession -session $vmSession -baseFolder $ProjectRoot -subFolders (@("scripts") + $settings.appFolders.Split(',') + $settings.testFolders.Split(','))

    $tempLicenseFile = CopyFileToSession -session $vmSession -LocalFile $licenseFile -returnSecureString
    $tempCodeSignPfxFile = CopyFileToSession -session $vmSession -LocalFile $codeSignPfxFile -returnSecureString

    Invoke-Command -Session $vmSession -ScriptBlock { Param($ProjectRoot, $containerName, $imageVersion, $credential, $licenseFile, $settings, $codeSignPfxFile, $codeSignPfxPassword)

        $ErrorActionPreference = "Stop"

        cd (Join-Path $ProjectRoot "scripts")

        $buildEnv = "AzureVM"
        $navContainerHelperPath = "C:\DEMO\navcontainerhelper-dev\NavContainerHelper.ps1"

        $buildArtifactFolder = Join-Path $ProjectRoot ".output"
        if (Test-Path $buildArtifactFolder) { Remove-Item $buildArtifactFolder -Force -Recurse }
        New-Item -Path $buildArtifactFolder -ItemType Directory -Force | Out-Null

        $alPackagesFolder = Join-Path $ProjectRoot ".alPackages"
        if (Test-Path $alPackagesFolder) { Remove-Item $alPackagesFolder -Force -Recurse }
        New-Item -Path $alPackagesFolder -ItemType Directory -Force | Out-Null

        . ".\Install-NavContainerHelper.ps1" `
            -buildEnv $buildEnv `
            -navContainerHelperPath $navContainerHelperPath

        . ".\Create-Container.ps1" `
            -buildEnv $buildEnv `
            -ContainerName $containerName `
            -artifact $imageVersion.artifact `
            -imageName $imageVersion.imageName `
            -Credential $credential `
            -licenseFile $licenseFile

        . ".\Compile-App.ps1" `
            -buildEnv $buildEnv `
            -ContainerName $containerName `
            -Credential $credential `
            -buildArtifactFolder $buildArtifactFolder `
            -buildProjectFolder $ProjectRoot `
            -buildSymbolsFolder $alPackagesFolder `
            -appFolders $settings.appFolders

        . ".\Compile-App.ps1" `
            -buildEnv $buildEnv `
            -ContainerName $containerName `
            -Credential $credential `
            -buildArtifactFolder $buildArtifactFolder `
            -buildProjectFolder $ProjectRoot `
            -buildSymbolsFolder $alPackagesFolder `
            -appFolders $settings.testFolders

        if ($CodeSignPfxFile) {
            . ".\Sign-App.ps1" `
                -buildEnv $buildEnv `
                -ContainerName $containerName `
                -buildArtifactFolder $buildArtifactFolder `
                -appFolders $settings.appFolders `
                -pfxFile $CodeSignPfxFile `
                -pfxPassword $CodeSignPfxPassword
        }
        . ".\Publish-App.ps1" `
            -buildEnv $buildEnv `
            -ContainerName $containerName `
            -buildArtifactFolder $buildArtifactFolder `
            -buildProjectFolder $ProjectRoot `
            -appFolders $settings.appFolders `
            -skipVerification:(!($CodeSignPfxFile))

        . ".\Publish-App.ps1" `
            -buildEnv $buildEnv `
            -ContainerName $containerName `
            -buildArtifactFolder $buildArtifactFolder `
            -buildProjectFolder $ProjectRoot `
            -appFolders $settings.testFolders `
            -skipVerification

        . ".\Run-Tests.ps1" `
            -buildEnv $buildEnv `
            -ContainerName $containerName `
            -Credential $credential `
            -testResultsFile (Join-Path $buildArtifactFolder "TestResults.xml") `
            -buildProjectFolder $ProjectRoot `
            -appFolders $settings.testFolders

        . ".\Remove-Container.ps1" `
            -buildEnv $buildEnv `
            -ContainerName $containerName

    } -ArgumentList $vmFolder, $containerName, $imageVersion, $credential, $tempLicenseFile, $settings, $tempCodeSignPfxFile, $codeSignPfxPassword
    
    Copy-Item -FromSession $vmSession -Path (Join-Path $vmFolder ".output") -Destination $ProjectRoot -Force -recurse
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
        if ($tempCodeSignPfxfile) {
            try { RemoveFileFromSession -session $vmSession -filename $tempCodeSignPfxFile } catch {}
        }
        if ($vmFolder) {
            try { RemoveFolderFromSession -session $vmSession -foldername $vmFolder } catch {}
        }
        Remove-PSSession -Session $vmSession
    }
}
