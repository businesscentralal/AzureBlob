Param(
    [ValidateSet('AzureDevOps','Local','AzureVM')]
    [Parameter(Mandatory=$false)]
    [string] $buildEnv = "AzureDevOps",

    [Parameter(Mandatory=$false)]
    [string] $version = $ENV:VERSION,

    [Parameter(Mandatory=$false)]
    [string] $buildProjectFolder = $ENV:BUILD_REPOSITORY_LOCALPATH,

    [Parameter(Mandatory=$false)]
    [string] $appVersion = ""
)

if ($appVersion) {
    write-host "##vso[build.updatebuildnumber]$appVersion"
}

$settings = (Get-Content (Join-Path $buildProjectFolder "scripts\settings.json") | ConvertFrom-Json)

$imageName = "build"
$property = $settings.PSObject.Properties.Match('imageName')
if ($property.Value) {
    $imageName = $property.Value
}

$property = $settings.PSObject.Properties.Match('navContainerHelperVersion')
if ($property.Value) {
    $navContainerHelperVersion = $property.Value
}
else {
    $navContainerHelperVersion = "latest"
}
Write-Host "Set navContainerHelperVersion = $navContainerHelperVersion"
Write-Host "##vso[task.setvariable variable=navContainerHelperVersion]$navContainerHelperVersion"

$appFolders = $settings.appFolders
Write-Host "Set appFolders = $appFolders"
Write-Host "##vso[task.setvariable variable=appFolders]$appFolders"

$testFolders = $settings.testFolders
Write-Host "Set testFolders = $testFolders"
Write-Host "##vso[task.setvariable variable=testFolders]$testFolders"

if ("$($ENV:AGENT_NAME)" -eq "Hosted Agent" -or "$($ENV:AGENT_NAME)" -like "Azure Pipelines*") {
    $containerNamePrefix = ""
    Write-Host "Set imageName = ''"
    Write-Host "##vso[task.setvariable variable=imageName]"
}
else {
    if ($imageName -eq "") {
        $containerNamePrefix = "bld-"
    }
    else {
        $containerNamePrefix = "$imageName-"
    }
    Write-Host "Set imageName = $imageName"
    Write-Host "##vso[task.setvariable variable=imageName]$imageName"
}
$containerName = "$($containerNamePrefix)$("$($ENV:AGENT_NAME)" -replace '[^a-zA-Z0-9]', '')"
Write-Host "Set containerName = $containerName"
Write-Host "##vso[task.setvariable variable=containerName]$containerName"
