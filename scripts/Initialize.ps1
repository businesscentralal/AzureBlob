$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

. (Join-Path $PSScriptRoot "SessionFunctions.ps1")

$ProjectRoot = (Get-Item (Join-Path $PSScriptRoot "..")).FullName

$settings = (Get-Content (Join-Path $ProjectRoot "scripts\settings.json") | ConvertFrom-Json)

$defaultVersion = $settings.versions[0].version
$version = Read-Host ("Select Version (" +(($settings.versions | ForEach-Object { $_.version }) -join ", ") + ") (default $defaultVersion)")
if (!($version)) {
    $version = $defaultVersion
}

$defaultUserProfile = $settings.userProfiles | Where-Object { $_.profile -eq "$($env:COMPUTERNAME)\$($env:USERNAME)" }
if (!($defaultUserProfile)) {
    $defaultUserProfile = $settings.userProfiles | Where-Object { $_.profile -eq $env:USERNAME }
    if (!($defaultUserProfile)) {
        $defaultUserProfile = $settings.userProfiles | Where-Object { $_.profile -eq "default" }
    }
}

if ($defaultUserProfile) {
    $profile = $defaultUserProfile.profile
}
else {
    $defaultUserProfile = $settings.userProfiles[0]
    $profile = Read-Host ("Select User Profile (" +(($settings.userProfiles | ForEach-Object { $_.profile }) -join ", ") + ") (default $($defaultUserProfile.profile))")
}

$userProfile = $settings.userProfiles | Where-Object { $_.profile -eq $profile }
$imageversion = $settings.versions | Where-Object { $_.version -eq $version }
if (!($imageversion)) {
    throw "No version for $version in settings.json"
}
if (-not ($imageversion.PSObject.Properties.Name -eq "reuseContainer")) {
    $imageversion | Add-Member -NotePropertyName reuseContainer -NotePropertyValue $false
}
if (-not ($imageversion.PSObject.Properties.Name -eq "imageName")) {
    $imageversion | Add-Member -NotePropertyName imageName -NotePropertyValue $false
}
if (-not ($imageversion.PSObject.Properties.Name -eq "insiderBuild")) {
    $imageversion | Add-Member -NotePropertyName insiderBuild -NotePropertyValue $false
}

if ($userProfile.licenseFilePath) {
    $licenseFile = try { $userProfile.licenseFilePath | ConvertTo-SecureString } catch { ConvertTo-SecureString -String $userProfile.licenseFilePath -AsPlainText -Force }
}
else {
    $licenseFile = $null
}

$securePassword = try { $userProfile.Password | ConvertTo-SecureString } catch { ConvertTo-SecureString -String $userProfile.Password -AsPlainText -Force }
$credential = New-Object PSCredential($userProfile.Username, $securePassword)

$CodeSignPfxFile = $null
if (($userProfile.PSObject.Properties.name -eq "CodeSignPfxFilePath") -and ($userProfile.PSObject.Properties.name -eq "CodeSignPfxPassword")) {
    $CodeSignPfxFile = try { $userProfile.CodeSignPfxFilePath | ConvertTo-SecureString } catch { ConvertTo-SecureString -String $userProfile.CodeSignPfxFilePath -AsPlainText -Force }
    $CodeSignPfxPassword = try { $userProfile.CodeSignPfxPassword | ConvertTo-SecureString } catch { ConvertTo-SecureString -String $userProfile.CodeSignPfxPassword -AsPlainText -Force }
}

$env:InsiderSasToken = $null
if ($imageversion.insiderBuild) {
    if (($userProfile.PSObject.Properties.name -eq "InsiderSasToken")) {
        $env:InsiderSasToken = try { $userProfile.InsiderSasToken | ConvertTo-SecureString } catch { ConvertTo-SecureString -String $userProfile.InsiderSasToken -AsPlainText -Force }
    }
}

$TestSecret = $null
if (($userProfile.PSObject.Properties.name -eq "TestSecret")) {
    $TestSecret = try { $userProfile.TestSecret | ConvertTo-SecureString } catch { ConvertTo-SecureString -String $userProfile.TestSecret -AsPlainText -Force }
}

Function UpdateLaunchJson {
    Param(
        [string] $Name,
        [string] $Server,
        [int] $Port = 7049,
        [string] $ServerInstance = "BC"
    )
    
    $launchSettings = [ordered]@{ "type" = "al";
                                  "request" = "launch";
                                  "name" = "$Name"; 
                                  "server" = "$Server"
                                  "serverInstance" = $serverInstance
                                  "port" = $Port
                                  "tenant" = ""
                                  "authentication" =  "UserPassword"
    }
    
    $settings = (Get-Content (Join-Path $ProjectRoot "scripts\settings.json") | ConvertFrom-Json)
    
    $settings.launch.PSObject.Properties | % {
        $setting = $_
        $launchSetting = $launchSettings.GetEnumerator() | Where-Object { $_.Name -eq $setting.Name }
        if ($launchSetting) {
            $launchSettings[$_.Name] = $_.Value
        }
        else {
            $launchSettings += @{ $_.Name = $_.Value }
        }
    }
    
    Get-ChildItem $ProjectRoot -Directory | ForEach-Object {
        $folder = $_.FullName
        $launchJsonFile = Join-Path $folder ".vscode\launch.json"
        if (Test-Path $launchJsonFile) {
            Write-Host "Modifying $launchJsonFile"
            $launchJson = Get-Content $LaunchJsonFile | ConvertFrom-Json
            $launchJson.configurations = @($launchJson.configurations | Where-Object { $_.name -ne $launchsettings.name })
            $launchJson.configurations += $launchSettings
            $launchJson | ConvertTo-Json -Depth 10 | Set-Content $launchJsonFile
        }
    }
}
