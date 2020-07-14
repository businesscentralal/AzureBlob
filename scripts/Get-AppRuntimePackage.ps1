Param(
    [ValidateSet('AzureDevOps','Local','AzureVM')]
    [Parameter(Mandatory=$false)]
    [string] $buildEnv = "AzureDevOps",

    [Parameter(Mandatory=$false)]
    [string] $containerName = $ENV:CONTAINERNAME,

    [Parameter(Mandatory=$false)]
    [string] $buildArtifactFolder = $ENV:BUILD_ARTIFACTSTAGINGDIRECTORY,

    [Parameter(Mandatory=$true)]
    [string] $appFolders,

    [Parameter(Mandatory=$false)]
    [string] $appVersion = ""
)

Sort-AppFoldersByDependencies -appFolders $appFolders.Split(',') -baseFolder $buildArtifactFolder -WarningAction SilentlyContinue | ForEach-Object {

    $appFolder = $_

    $appFile = (Get-Item (Join-Path $buildArtifactFolder "$appFolder\*.app")).FullName
    $appJsonFile = (Get-Item (Join-Path $buildArtifactFolder "$appFolder\app.json")).FullName
    $appJson = Get-Content $appJsonFile | ConvertFrom-Json

    if (-not ($appVersion)) {
        $appVersion = $appJson.Version
    }

    $runtimeAppFolder = Join-Path $buildArtifactFolder "RuntimePackages\$appFolder"
    New-Item -Path $runtimeAppFolder -ItemType Directory | Out-Null

    Write-Host "Getting Runtime Package $appFolder"
    Get-NavContainerAppRuntimePackage -containerName $containerName -appName $appJson.name -appVersion $appVersion -publisher $appJson.Publisher -appFile (Join-Path $runtimeAppFolder ([System.IO.Path]::GetFileName($appFile)))
}
