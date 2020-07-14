$path = Join-Path $PSScriptRoot ".."

$launchJson = [ordered]@{
    "version" = "0.2.0"
    "configurations" = @([ordered]@{
        "type" =  "al"
        "request" =  "launch"
        "name" = "My sandbox environment"
        "server" = "https://fksandtest.northeurope.cloudapp.azure.com"
        "serverInstance" = "BC"
        "port" = 7049
        "tenant" = ""
        "authentication" = "UserPassword"
        "startupObjectId" = 22
        "startupObjectType" = "Page"
        "breakOnError" = $true
    })
}

$replaceValues = @{
    "00000000-0000-0000-0000-000000000001" = [Guid]::NewGuid().ToString()
    "00000000-0000-0000-0000-000000000002" = [Guid]::NewGuid().ToString()
    "00000000-0000-0000-0000-000000000003" = [Guid]::NewGuid().ToString()
    "Default Publisher" = "My Name"
    "Default App Name" = "My App"
    "Default Base App Name" = "My Base App"
    "Default Test App Name" = "My Test App"
    "1.0.0.0" = "2.0.0.0"
}

function ReplaceProperty { Param ($object, $property)
    if ($object.PSObject.Properties.name -eq $property) {
        $str = $object."$property"
        if ($replaceValues.ContainsKey($str)) {
            Write-Host "- change $property from $str to $($replaceValues[$str]) "
            $object."$property" = $replaceValues[$str]
        }
    }
}

function ReplaceObject { Param($object)
    "id", "appId", "name", "publisher", "version" | ForEach-Object {
        ReplaceProperty -object $object -property $_
    }
}

Get-ChildItem -Path $path | Where-Object { $_.psIsContainer -and $_.Name -notlike ".*" } | Get-ChildItem -Recurse -filter "app.json" | ForEach-Object {
    $appJsonFile = $_.FullName
    $appJson = Get-Content $appJsonFile | ConvertFrom-Json
    Write-Host -ForegroundColor Yellow $appJsonFile
    ReplaceObject -object $appJson
    Write-Host "Check Dependencies"
    $appJson.dependencies | ForEach-Object { ReplaceObject($_) }
    $appJson | ConvertTo-Json -Depth 10 | Set-Content $appJsonFile
}

Get-ChildItem -Path $path | Where-Object { $_.psIsContainer -and $_.Name -notlike ".*" } | Get-ChildItem -Recurse -filter "launch.json" | ForEach-Object {
    $launchJsonFile = $_.FullName
    $existingLaunchJson = Get-Content $launchJsonFile | ConvertFrom-Json
    Write-Host -ForegroundColor Yellow $launchJsonFile
    $launchJson.configurations[0].startupObjectId = $existinglaunchJson.configurations[0].startupObjectId
    $launchJson | ConvertTo-Json -Depth 10 | Set-Content $launchJsonFile
}
