#requires -RunAsAdministrator


<#PSScriptInfo

.VERSION 1.0.2

.GUID 48fcb5e2-0e6a-4a93-9699-f44fc7156482

.AUTHOR kvprasoon

.COMPANYNAME PSBUG

.COPYRIGHT kvprasoon

.TAGS pwsh powershell upgrade

.LICENSEURI 

.PROJECTURI https://github.com/kvprasoon/PwshUtils/blob/master/Utilities/UpdatePwsh.ps1

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES

7/21/2018
Added -Prerelease switch which option of installing Release or pre release version.

7/20/2018
Upgrade pwsh script support is currently available only for below Operating Systems.
 - Windows
#> 







<#

.DESCRIPTION
 Script to upgrade pwsh to the latest available release(Only for windows now) 

.EXAMPLE
.\UpgarePwsh.ps1

The above command will install the latest released version of PowerShell core.

.EXAMPLE
.\UpgarePwsh.ps1 -PreRelease

The above command will install the latest pre release version of PowerShell core.

#> 

Param(
    # Use -PreRelease switch to install pre release version of PowerShell core.
    [Parameter()]
    [switch]$Prerelease
)
function InstallForWindows{
    Param(
        $Release
    )
    $OutputPath = "$env:HOMEPATH\Downloads"

    if( [Environment]::Is64BitOperatingSystem ){
        $FilterCriteria  = { ($_.Name -match '.msi') -and ($_.Name -match "x64") }
    }
    else{
        $FilterCriteria  = { ($_.Name -match '.msi') -and ($_.Name -match "x86") }
    }

    Write-Host "Latest released packages are below"
    $RequiredPackage = $Release | Where-Object $FilterCriteria 
      
    $DownloadPath = "$OutputPath\$($RequiredPackage.Name)"
        
    Write-Host "Downloading latest release $($RequiredPackage.Name) "
    Invoke-WebRequest $RequiredPackage.Browser_Download_Url -Out "$DownloadPath" -ErrorAction Stop
    
    
    Write-Host "Installing $($RequiredPackage.Name)"
@"
msiexec /i $DownloadPath /quiet 
start pwsh
"@ | Out-File -FilePath $env:Temp\UpdatePwsh.bat
    Start-Process -FilePath $env:Temp\UpdatePwsh.bat -ErrorAction Stop

    Write-Host -ForegroundColor Green "Have fun using Pwsh ..."
    

}
try{

    $Script:pwsh    = 'pwsh'
    $ReleaseUrl     = "https://api.github.com/repos/PowerShell/PowerShell/releases"
    $MetadataUrl    = "https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/metadata.json"
    $CurrentVersion = $PSVersionTable.PSVersion -as [string]

    Write-Host "Installed pwsh version is $CurrentVersion"
    Write-Host "Fetching latest releases"

    $ReleaseMetadata = Invoke-RestMethod -Uri $MetadataUrl -ErrorAction Stop
    
    If( $PreRelease.IsPresent ){
        $ReleseToDownload = $ReleaseMetadata.NextReleaseTag
    }
    else{
        $ReleseToDownload = $ReleaseMetadata.ReleaseTag
    }

    $Releases = Invoke-RestMethod -Uri $ReleaseUrl
    $LatestRelease = ($Releases | Where-Object -FilterScript { $_.Tag_Name -eq $ReleseToDownload }).assets | Select-Object -Property Name,Browser_Download_Url -ErrorAction Stop

    If( $LatestRelease.Name -like "*$CurrentVersion*" ){
        Write-Host "Currenlty executing pwsh is with latest available version"        
    }
    else{
        InstallForWindows -Release $LatestRelease 
        Stop-Process -Name pwsh -Force -ErrorAction Stop
    }

}
Catch{
    Throw "pwsh update failed due to $_"
}
