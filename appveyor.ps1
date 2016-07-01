
[string[]]$repos = 'https://github.com/StackExchange/dapper-dot-net',
                    'https://github.com/xunit/xunit',
                    'https://github.com/MvvmCross/MvvmCross',
                    'https://github.com/JamesNK/Newtonsoft.Json',
                    'https://github.com/aspnet/entityframework'

function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

$scriptDir = ((Get-ScriptDirectory) + "\")

$helperpath = (Join-Path $scriptDir 'helper.ps1')
if(-not (Test-Path $helperpath -PathType Leaf)){
    throw ('file not found at {0}' -f $helperpath)
}

# inline the script
. $helperpath

#[string[]]$repoDirs = @()
$tempDir = (Join-Path ([System.IO.Path]::GetTempPath()) ('xcompile\{0}' -f ([datetime]::Now.Ticks)))
New-Item -Path $tempDir -ItemType Directory
foreach($r in $repos){
    $repoDir = (CloneRepo -url $r)
    [System.IO.DirectoryInfo]$dirInfo = $repoDir
    
    $reportPath = (Join-Path $tempDir ('{0}.txt' -f $dirInfo.Name))
    Get-Ifdef -path $repoDir | Out-File $reportPath
    Push-AppveyorArtifact $reportPath
}
# create zip file
$zipfile = (Join-Path $tempDir all.zip)
if(Test-Path -Path $zipfile){
    Remove-Item $zipfile
}

New-ZipFile -ZipFilePath $zipfile -rootFolder $tempDir -InputObject ((Get-ChildItem -Path $tempDir *.txt -Recurse -Filter).FullName)
Push-AppveyorArtifact $zipfile


<#

$reportPath = (Join-Path ([System.IO.Path]::GetTempPath()) 'xcompile-report.txt')
if(Test-Path $reportPath){
    Remove-Item $reportPath
}

foreach($rd in $repoDirs){
    $reportPath = (Join-Path
    Get-Ifdef -path $rd
}

Get-Ifdef -path $repoDirs | Out-File $reportPath -Append

Push-AppveyorArtifact $reportPath
#>