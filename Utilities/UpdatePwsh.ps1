
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
    Invoke-WebRequest $RequiredPackage.Browser_Download_Url -Out "$DownloadPath" 
    
    
    Write-Host "Installing $($RequiredPackage.Name)"
    "msiexec /i $DownloadPath /quiet "| Out-File -FilePath $env:Temp\UpdatePwsh.bat
    Start-Process -FilePath $env:Temp\UpdatePwsh.bat

    Write-Host -ForegroundColor Green "Have fun using Pwsh ..."
    

}

$Script:pwsh = 'pwsh'
$ReleaseUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases"
$CurrentVersion = $PSVersionTable.PSVersion -as [string]
Write-Host "Installed pwsh version is $CurrentVersion"
Write-Host "Fetching latest releases"
$Release = (Invoke-WebRequest $ReleaseUrl | ConvertFrom-Json)[0].assets | Select-Object -Property Name,Browser_Download_Url

If( $Release.Name -like "*$CurrentVersion*" ){
    Write-Host "Currenlty executing pwsh is with latest available version"
    break
}

InstallForWindows -Release $Release 

[environment]::Exit(0)
