
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

[string[]]$repoDirs = @()

foreach($r in $repos){
    $repoDirs += (CloneRepo -url $r)
}

$reportPath = (Join-Path ([System.IO.Path]::GetTempPath()) 'xcompile-report.txt')
if(Test-Path $reportPath){
    Remove-Item $reportPath
}

Get-Ifdef -path $repoDirs | Out-File $reportPath -Append

Push-AppveyorArtifact $reportPath
