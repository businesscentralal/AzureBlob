Param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('AzureVM','onlineTenant')]
    [string] $deploymentType,

    [Parameter(Mandatory=$true)]
    [string] $artifactsFolder,

    [Parameter(Mandatory=$true)]
    [string] $appFolders,

    [Parameter(Mandatory=$false)]
    [pscredential] $credential = $null,

    [Parameter(Mandatory=$false)]
    [string] $apiBaseUrl = $ENV:APIBASEURL,

    [Parameter(Mandatory=$false)]
    [pscredential] $vmcredential = $null,

    [Parameter(Mandatory=$false)]
    [string] $azureVM = $ENV:AZUREVM,

    [Parameter(Mandatory=$false)]
    [string] $containerName = $ENV:CONTAINERNAME 

)

$artifactsFolder = (Get-Item $artifactsFolder).FullName
Write-Host "Folder: $artifactsFolder"

Sort-AppFoldersByDependencies -appFolders $appFolders.Split(',') -baseFolder $artifactsFolder -WarningAction SilentlyContinue | ForEach-Object {

    $appFolder = $_
    $appFile = (Get-Item (Join-Path $artifactsFolder "$appFolder\*.app")).FullName
    $appJsonFile = (Get-Item (Join-Path $artifactsFolder "$appFolder\app.json")).FullName
    $appJson = Get-Content $appJsonFile | ConvertFrom-Json

    if ($deploymentType -eq "AzureVM") {
    
        . (Join-Path $PSScriptRoot "SessionFunctions.ps1")
    
        $useSession = $true
        try { 
            $myip = ""; $myip = (Invoke-WebRequest -Uri http://ifconfig.me/ip).Content
            $targetip = (Resolve-DnsName $azureVM).IP4Address
            if ($myip -eq $targetip) {
                $useSession = $false
            }
        }
        catch { }
    
        $vmSession = $null
        $tempAppFile = ""
        try {
    
            if ($useSession) {
                $sessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck
                $vmSession = New-PSSession -ComputerName $azureVM -Credential $vmCredential -UseSSL -SessionOption $sessionOption
                $tempAppFile = CopyFileToSession -session $vmSession -localFile $appFile
                $sessionArgument = @{ "Session" = $vmSession }
            }
            else {
                $tempAppFile = $appFile
                $sessionArgument = @{ }
            }
    
            Invoke-Command @sessionArgument -ScriptBlock { Param($containerName, $appFile, $credential)
                $ErrorActionPreference = "Stop"
    
                $appExists = $false
                $apps = Get-BCContainerAppInfo $containerName -tenantSpecificProperties | Sort-Object -Property Name
                Write-Host "Extensions:"
                $apps | % {
                    Write-Host " - $($_.Name) v$($_.version) installed=$($_.isInstalled)"
                    if ($_.publisher -eq $appJson.publisher -and $_.name -eq $appjson.name -and $_.appid -eq $appjson.id) {
                        UnPublish-BCContainerApp -containerName $containerName -appName $_.name -publisher $_.publisher -version $_.Version -unInstall -force
                        $appExists = $true
                    }
                }

                Publish-BCContainerApp -containerName $containerName -appFile $appFile -skipVerification -sync -scope Tenant
                if ($appExists) {
                    Start-BCContainerAppDataUpgrade -containerName $containerName -appName $appJson.name -appVersion $appJson.version
                }

                Install-BCContainerApp -containerName $containerName -appName $appJson.name -appVersion $appJson.version
    
            } -ArgumentList $containerName, $tempAppFile, $credential
        }
        catch [System.Management.Automation.Remoting.PSRemotingTransportException] {
            throw "Could not connect to $azureVM. Maybe port 5986 (WinRM) is not open for your IP address $myip"
        }
        finally {
            if ($vmSession) {
                if ($tempAppFile) {
                    try { RemoveFileFromSession -session $vmSession -filename $tempAppFile } catch {}
                }
                Remove-PSSession -Session $vmSession
            }
        }
    }
    elseif ($deploymentType -eq "onlineTenant") {
    
        $baseUrl = $apiBaseUrl.TrimEnd('/')
        Write-Host "Base Url: $baseurl"
        
        # Get company id (of any company in the tenant)​
        $companiesResponse = Invoke-WebRequest -Uri "$baseUrl/v1.0/companies" -Credential $credential
        $companiesContent = $companiesResponse.Content
        $companyId = (ConvertFrom-Json $companiesContent).value[0].id
       
        Write-Host "CompanyId $companyId"
        
        # Get existing extensions
        $getExtensions = Invoke-WebRequest `
            -Method Get `
            -Uri "$baseUrl/microsoft/automation/v1.0/companies($companyId)/extensions" `
            -Credential $credential
        
        $extensions = (ConvertFrom-Json $getExtensions.Content).value | Sort-Object -Property DisplayName
        
        Write-Host "Extensions:"
        $extensions | % { Write-Host " - $($_.DisplayName) v$($_.versionMajor).$($_.versionMinor) installed=$($_.isInstalled)" }
        
        # Publish and install extension
        Write-Host "Publishing and installing $appFolder"
        Invoke-WebRequest `
            -Method Patch `
            -Uri "$baseUrl/microsoft/automation/v1.0/companies($companyId)/extensionUpload(0)/content" `
            -Credential $credential `
            -ContentType "application/octet-stream" `
            -Headers @{"If-Match" = "*"} `
            -InFile $appFile | Out-Null
        
        Write-Host ""
        Write-Host "Deployment status:"
        
        # Monitor publishing progress
        $inprogress = $true
        $completed = $false
        $errCount = 0
        while ($inprogress)
        {
            Start-Sleep -Seconds 5
            try {
                $extensionDeploymentStatusResponse = Invoke-WebRequest `
                    -Method Get `
                    -Uri "$baseUrl/microsoft/automation/v1.0/companies($companyId)/extensionDeploymentStatus" `
                    -Credential $credential
                $extensionDeploymentStatuses = (ConvertFrom-Json $extensionDeploymentStatusResponse.Content).value
                $inprogress = $false
                $completed = $true
                $extensionDeploymentStatuses | Where-Object { $_.publisher -eq $appJson.publisher -and $_.name -eq $appJson.name -and $_.appVersion -eq $appJson.version } | % {
                    Write-Host " - $($_.name) $($_.appVersion) $($_.operationType) $($_.status)"
                    if ($_.status -eq "InProgress") { $inProgress = $true }
                    if ($_.status -ne "Completed") { $completed = $false }
                }
                $errCount = 0
            }
            catch {
                if ($errCount++ -gt 3) {
                    $inprogress = $false
                }
            }
        }
        if (!$completed) {
            throw "Unable to publish app"
        }
    }
}