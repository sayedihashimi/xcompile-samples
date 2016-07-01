
[string[]]$repos = 'https://github.com/StackExchange/dapper-dot-net',
                    'https://github.com/xunit/xunit',
                    'https://github.com/nunit/nunit',
                    'https://github.com/moq/moq4',
                    'https://github.com/antlr/antlrcs',
                    'https://github.com/MvvmCross/MvvmCross',
                    'https://github.com/JamesNK/Newtonsoft.Json',
                    'https://github.com/aspnet/entityframework',
                    'https://github.com/aspnet/Routing',
                    'https://github.com/aspnet/Microsoft.Data.Sqlite',
                    'https://github.com/aspnet/Razor',
                    'https://github.com/aspnet/Caching',
                    'https://github.com/aspnet/Common',
                    'https://github.com/Azure/azure-storage-net'

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

$tempDir = (Join-Path ([System.IO.Path]::GetTempPath()) ('xcompile\{0}' -f ([datetime]::Now.Ticks)))
New-Item -Path $tempDir -ItemType Directory
foreach($r in $repos){
    $repoDir = (CloneRepo -url $r)
    [System.IO.DirectoryInfo]$dirInfo = $repoDir
    
    [System.Uri]$ruri = $r
    $projname = $ruri.Segments[$ruri.Segments.Count -1]
    $reportPath = (Join-Path $tempDir ('{0}.txt' -f $projname))
    Get-Ifdef -path $repoDir | Out-File $reportPath
    
    if(Test-Path $reportPath){
        Push-AppveyorArtifact $reportPath
    }
}
# create zip file
$zipfile = (Join-Path $tempDir all.zip)
if(Test-Path -Path $zipfile){
    Remove-Item $zipfile
}

New-ZipFile -ZipFilePath $zipfile -rootFolder $tempDir -InputObject ((Get-ChildItem -Path $tempDir *.txt -Recurse -File).FullName)
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