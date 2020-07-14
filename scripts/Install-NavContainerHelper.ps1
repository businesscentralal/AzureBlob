Param(
    [ValidateSet('AzureDevOps','Local','AzureVM')]
    [string] $buildEnv = "AzureDevOps",

    [Parameter(Mandatory=$false)]
    [string] $navContainerHelperPath = $env:navContainerHelperPath,

    [Parameter(Mandatory=$false)]
    [string] $navContainerHelperVersion = $env:navContainerHelperVersion
)

if (-not $navContainerHelperVersion) { $navContainerHelperVersion = "latest" }

Write-Host "Version: $navContainerHelperVersion"

if ($navContainerHelperPath -ne "" -and (Test-Path $navContainerHelperPath)) {

    Write-Host "Using NavContainerHelper from $navContainerHelperPath"
    . $navContainerHelperPath

}
else {

    $module = Get-InstalledModule -Name navcontainerhelper -ErrorAction SilentlyContinue
    if ($module) {
        $versionStr = $module.Version.ToString()
        Write-Host "NavContainerHelper $VersionStr is installed"
        if ($navContainerHelperVersion -eq "latest") {
            Write-Host "Determine latest NavContainerHelper version"
            $latestVersion = (Find-Module -Name navcontainerhelper).Version
            $navContainerHelperVersion = $latestVersion.ToString()
            Write-Host "NavContainerHelper $navContainerHelperVersion is the latest version"
        }
        if ($navContainerHelperVersion -ne $module.Version) {
            Write-Host "Updating NavContainerHelper to $navContainerHelperVersion"
            Update-Module -Name navcontainerhelper -Force -RequiredVersion $navContainerHelperVersion
            Write-Host "NavContainerHelper updated"
        }
    }
    else {
        if (!(Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
            Write-Host "Installing NuGet Package Provider"
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.208 -Force -WarningAction SilentlyContinue | Out-Null
        }
        if ($navContainerHelperVersion -eq "latest") {
            Write-Host "Installing NavContainerHelper"
            Install-Module -Name navcontainerhelper -Force
        }
        else {
            Write-Host "Installing NavContainerHelper version $navContainerHelperVersion"
            Install-Module -Name navcontainerhelper -Force -RequiredVersion $navContainerHelperVersion
        }
        $module = Get-InstalledModule -Name navcontainerhelper -ErrorAction SilentlyContinue
        $versionStr = $module.Version.ToString()
        Write-Host "NavContainerHelper $VersionStr installed"
    }
}
