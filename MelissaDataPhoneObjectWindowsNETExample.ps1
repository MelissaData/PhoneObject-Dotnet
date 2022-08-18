# Name:    MelissaDataPhoneObjectWindowsNET
# Purpose: Use the Melissa Updater to make the MelissaDataPhoneObjectWindowsNET example usable


######################### Parameters ##########################

param($phone ='""', $license = '', [switch]$quiet = $false )

######################### Classes ##########################

class DLLConfig {
  [string] $FileName;
  [string] $ReleaseVersion;
  [string] $OS;
  [string] $Compiler;
  [string] $Architecture;
  [string] $Type;
}

######################### Config ###########################

$RELEASE_VERSION = '2022.08'
$ProductName = "DQ_PHONE_DATA"

# Uses the location of the .ps1 file 
# Modify this if you want to use 
$CurrentPath = $PSScriptRoot
Set-Location $CurrentPath
$ProjectPath = "$CurrentPath\MelissaDataPhoneObjectWindowsNETExample"
$DataPath = Join-Path -Path $ProjectPath -ChildPath 'Data'
If (!(Test-Path $DataPath)) {
  New-Item -Path $ProjectPath -Name 'Data' -ItemType "directory"
}

If (!(Test-Path $ProjectPath\Build)) {
  New-Item -Path $ProjectPath -Name 'Build' -ItemType "directory"
}


$DLLs = @(
  [DLLConfig]@{
    FileName       = "mdPhone.dll";
    ReleaseVersion = $RELEASE_VERSION;
    OS             = "WINDOWS";
    Compiler       = "DLL";
    Architecture   = "64BIT";
    Type           = "BINARY";
  },
  [DLLConfig]@{
    FileName       = "mdPhoneNET.dll";
    ReleaseVersion = $RELEASE_VERSION;
    OS             = "WINDOWS";
    Compiler       = "NET";
    Architecture   = "ANY";
    Type           = "INTERFACE";
  }
)

######################## Functions #########################

function DownloadDataFiles([string] $license) {
  $DataProg = 0
  Write-Host "========================== MELISSA UPDATER ========================="
  Write-Host "MELISSA UPDATER IS DOWNLOADING DATA FILES..."

  .\MelissaUpdater\MelissaUpdater.exe manifest -p $ProductName -r $RELEASE_VERSION -l $license -t $DataPath 
  if($? -eq $False ) {
    Write-Host "`nCannot run Melissa Updater. Please check your license string!"
    Exit
  }     
  Write-Host "Melissa Updater finished downloading data files!"

}

function DownloadDLLs() {
  Write-Host "MELISSA UPDATER IS DOWNLOADING DLLs..."
  $DLLProg = 0
  foreach ($DLL in $DLLs) {
    Write-Progress -Activity "Downloading DLLs" -Status "$([math]::round($DLLProg / $DLLs.Count * 100, 2))% Complete:"  -PercentComplete ($DLLProg / $DLLs.Count * 100)

    # Check for quiet mode
    if ($quiet) {
      .\MelissaUpdater\MelissaUpdater.exe file --filename $DLL.FileName --release_version $DLL.ReleaseVersion --license $LICENSE --os $DLL.OS --compiler $DLL.Compiler --architecture $DLL.Architecture --type $DLL.Type --target_directory $ProjectPath\Build > $null
      if(($?) -eq $False) {
          Write-Host "`nCannot run Melissa Updater. Please check your license string!"
          Exit
      }
    }
    else {
      .\MelissaUpdater\MelissaUpdater.exe file --filename $DLL.FileName --release_version $DLL.ReleaseVersion --license $LICENSE --os $DLL.OS --compiler $DLL.Compiler --architecture $DLL.Architecture --type $DLL.Type --target_directory $ProjectPath\Build 
      if(($?) -eq $False) {
          Write-Host "`nCannot run Melissa Updater. Please check your license string!"
          Exit
      }
    }
    
    Write-Host "Melissa Updater finished downloading " $DLL.FileName "!"
    $DLLProg++
  }
}

function CheckDLLs() {
  Write-Host "`nDouble checking dlls were downloaded...`n"
  $FileMissing = $false 
  if (!(Test-Path (Join-Path -Path $ProjectPath\Build -ChildPath "mdPhone.dll"))) {
    Write-Host "mdPhone.dll not found." 
    $FileMissing = $false
  }
  if (!(Test-Path (Join-Path -Path $ProjectPath\Build -ChildPath "mdPhoneNET.dll"))) {
    Write-Host "mdPhoneNET.dll not found." 
    $FileMissing = $true
  }
  if ($FileMissing) {
    Write-Host "`nMissing the above data files.  Please check that your license string and directory are correct."
    return $false
  }
  else {
    return $true
  }
}


########################## Main ############################

Write-Host "`n=============== Example of Melissa Data Phone Object ===============`n                    [ .NET | Windows | 64BIT ]`n"

# Get license (either from parameters or user input)
if ([string]::IsNullOrEmpty($license) ) {
  $License = Read-Host "Please enter your license string"
}

# Check for License from Environment Variables 
if ([string]::IsNullOrEmpty($License) ) {
  $License = $env:MD_LICENSE # Get-ChildItem -Path Env:\MD_LICENSE   #[System.Environment]::GetEnvironmentVariable('MD_LICENSE')
}

if ([string]::IsNullOrEmpty($License)) {
  Write-Host "`nLicense String is invalid!"
  Exit
}
# Use Melissa Updater to download data files 
# Download data files 
DownloadDataFiles -license $License      # comment out this line if using DQS Release

# Set data files path
#$DataPath = "E:\\Ha\\MelissaUpdaterDownloads\\ManifestTest\\Ha_mdPhone"      # uncomment this line and change to your DQS Release data files directory 

# Download dlls
DownloadDlls -license $License

# Check if all dlls have been downloaded Exit script if missing
$DLLsAreDownloaded = CheckDLLs
if (!$DLLsAreDownloaded) {
  Write-Host "`nAborting program, see above.  Press any button to exit."
  $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
  exit
}

Write-Host "All files have been downloaded/updated! "

# Start example
# Build project
Write-Host "`n=========================== BUILD PROJECT =========================="
dotnet publish -c Release -o .\MelissaDataPhoneObjectWindowsNETExample\Build MelissaDataPhoneObjectWindowsNETExample\MelissaDataPhoneObjectWindowsNETExample.csproj

# Run project
if ([string]::IsNullOrEmpty($phone)) {
  dotnet .\MelissaDataPhoneObjectWindowsNETExample\Build\MelissaDataPhoneObjectWindowsNETExample.dll --license $License  --dataPath $DataPath
}
else {
  dotnet .\MelissaDataPhoneObjectWindowsNETExample\Build\MelissaDataPhoneObjectWindowsNETExample.dll --license $License  --dataPath $DataPath --phone $phone
}
