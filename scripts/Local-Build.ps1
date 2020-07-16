cd $PSScriptRoot

. ".\Initialize.ps1"

$containerName = "$($settings.name)-bld"

$buildenv = "Local"
$navContainerHelperPath = $userProfile.navContainerHelperPath

$buildArtifactFolder = Join-Path $ProjectRoot ".output"
if (Test-Path $buildArtifactFolder) { Remove-Item $buildArtifactFolder -Force -Recurse }
New-Item -Path $buildArtifactFolder -ItemType Directory -Force | Out-Null

$alPackagesFolder = Join-Path $ProjectRoot ".alPackages"
if (Test-Path $alPackagesFolder) { Remove-Item $alPackagesFolder -Force -Recurse }
New-Item -Path $alPackagesFolder -ItemType Directory -Force | Out-Null

. ".\Install-NavContainerHelper.ps1" `
    -buildenv $buildenv `
    -navContainerHelperPath $navContainerHelperPath

. ".\Create-Container.ps1" `
    -buildenv $buildenv `
    -ContainerName $containerName `
    -artifact $imageVersion.artifact `
    -imageName $imageVersion.imageName `
    -Credential $credential `
    -licenseFile $licenseFile

. ".\Compile-App.ps1" `
    -buildenv $buildenv `
    -ContainerName $containerName `
    -Credential $credential `
    -buildArtifactFolder $buildArtifactFolder `
    -buildProjectFolder $ProjectRoot `
    -buildSymbolsFolder $alPackagesFolder `
    -appFolders $settings.appFolders

. ".\Compile-App.ps1" `
    -buildenv $buildenv `
    -ContainerName $containerName `
    -Credential $credential `
    -buildArtifactFolder $buildArtifactFolder `
    -buildProjectFolder $ProjectRoot `
    -buildSymbolsFolder $alPackagesFolder `
    -appFolders $settings.testFolders

if ($CodeSignPfxFile) {
    . ".\Sign-App.ps1" `
        -buildenv $buildenv `
        -ContainerName $containerName `
        -buildArtifactFolder $buildArtifactFolder `
        -appFolders $settings.appFolders `
        -codeSignPfxFile $CodeSignPfxFile `
        -codeSignPfxPassword $CodeSignPfxPassword
}

. ".\Publish-App.ps1" `
    -buildenv $buildenv `
    -ContainerName $containerName `
    -buildArtifactFolder $buildArtifactFolder `
    -buildProjectFolder $ProjectRoot `
    -appFolders $settings.appFolders `
    -skipVerification:(!($CodeSignPfxFile))

. ".\Publish-App.ps1" `
    -buildenv $buildenv `
    -ContainerName $containerName `
    -buildArtifactFolder $buildArtifactFolder `
    -buildProjectFolder $ProjectRoot `
    -appFolders $settings.testFolders `
    -skipVerification

if ($testSecret) {
    . ".\Set-TestSecret.ps1" `
        -buildenv $buildenv `
        -ContainerName $containerName `
        -companyName $settings.testMethod.companyName `
        -codeunitId $settings.testMethod.codeunitId `
        -methodName $settings.testMethod.methodName `
        -argument $testSecret
}

. ".\Run-Tests.ps1" `
    -buildenv $buildenv `
    -ContainerName $containerName `
    -Credential $credential `
    -testResultsFile (Join-Path $buildArtifactFolder "TestResults.xml") `
    -buildProjectFolder $ProjectRoot `
    -appFolders $settings.testFolders

. ".\Remove-Container.ps1" `
    -buildenv $buildenv `
    -ContainerName $containerName
