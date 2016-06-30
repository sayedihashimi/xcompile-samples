


<#
https://github.com/xunit/xunit/blob/master/src/abstractions/xunit.abstractions/Properties/AssemblyInfo.cs#L8

$res1.tostring().substring($res1.tostring().lastindexof(':')+1).Replace(' (fetch)','').trim()


$originstr = (git remote -v|Select-String 'origin.*fetch'|Select-Object -First 1).tostring();

$originstr |%{}
$res1.tostring().substring($res1.tostring().lastindexof(':')+1).Replace(' (fetch)','').trim()

.tostring().substring($originstr.lastindexof(':')+1).Replace(' (fetch)','').trim()


$res[0].RelativePath($pwd).replace('\','/')
#>

$baseurl = 'https://github.com/'
$originstr = (git remote -v|Select-String 'origin.*fetch'|Select-Object -First 1).tostring()
$repofrag = $originstr.tostring().tostring().substring($originstr.lastindexof(':')+1).Replace(' (fetch)','').replace('.git','').trim()
Get-ChildItem .\ *.cs -Recurse -File|select-string '#if' -SimpleMatch -Context 0|Select-Object -Unique -First 2 | %{
    '{0}{1}/blob/master/{2}#L{3}' -f $baseurl,$repofrag, ($_.RelativePath($pwd).replace('\','/')),$_.LineNumber
}


# $res[0].RelativePath($pwd).replace('\','/')


function Get-IfdefUrl{
    [cmdletbinding()]
    param(
        [string[]]$path,
        [string]$baseUrl = 'https://github.com/'
    )
    process{
        foreach($p in $path){
            try{
                Push-Location
                Set-Location $p
                $baseurl = 'https://github.com/'
                $originstr = (git remote -v|Select-String 'origin.*fetch'|Select-Object -First 1).tostring()
                $repofrag = $originstr.tostring().tostring().substring($originstr.lastindexof(':')+1).Replace(' (fetch)','').replace('.git','').trim()
                Get-ChildItem .\ *.cs -Recurse -File|select-string '#if' -SimpleMatch -Context 0 | %{
                    '{0}{1}/blob/master/{2}#L{3}' -f $baseurl,$repofrag, ($_.RelativePath($pwd).replace('\','/')),$_.LineNumber
                }
            }
            finally{
                Pop-Location
            }
        }
    }
}

function Get-Ifdef{
    [cmdletbinding()]
    param(
        [string[]]$path,
        [int]$context = 5
    )
    process{
        foreach($p in $path){
            try{
                Push-Location
                Set-Location $p
                $baseurl = 'https://github.com/'
                $originstr = (git remote -v|Select-String 'origin.*fetch'|Select-Object -First 1).tostring()
                $repofrag = $originstr.tostring().tostring().substring($originstr.lastindexof(':')+1).Replace(' (fetch)','').replace('.git','').trim()
                Get-ChildItem .\ *.cs -Recurse -File|select-string '#if' -SimpleMatch -Context $context|%{ "$_`r`n"}
            }
            finally{
                Pop-Location
            }
        }
    }
}

[string[]]$paths = 'C:\Data\mycode\xunit','C:\data\mycode\Newtonsoft.Json','C:\data\mycode\dapper-dot-net','C:\data\mycode\AutoMapper','c:\data\mycode\EntityFramework'
Get-Ifdef -path $paths
Get-IfdefUrl -path $paths