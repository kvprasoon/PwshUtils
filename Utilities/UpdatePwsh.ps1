#requires -RunAsAdministrator

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

    $Script:pwsh = 'pwsh'
    $ReleaseUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases"
    $CurrentVersion = $PSVersionTable.PSVersion -as [string]
    Write-Host "Installed pwsh version is $CurrentVersion"
    Write-Host "Fetching latest releases"
    $Release = (Invoke-WebRequest -Uri $ReleaseUrl | ConvertFrom-Json)[0].assets | Select-Object -Property Name,Browser_Download_Url -ErrorAction Stop

    If( $Release.Name -like "*$CurrentVersion*" ){
        Write-Host "Currenlty executing pwsh is with latest available version"
        [System.Environment]::Exit(0)
    }

    InstallForWindows -Release $Release 

    Stop-Process -Name pwsh -Force -ErrorAction Stop

}
Catch{
    Throw "pwsh update failed due to $_"
}
