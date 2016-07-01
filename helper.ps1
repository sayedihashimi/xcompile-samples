


<#
https://github.com/xunit/xunit/blob/master/src/abstractions/xunit.abstractions/Properties/AssemblyInfo.cs#L8

$res1.tostring().substring($res1.tostring().lastindexof(':')+1).Replace(' (fetch)','').trim()


$originstr = (git remote -v|Select-String 'origin.*fetch'|Select-Object -First 1).tostring();

$originstr |%{}
$res1.tostring().substring($res1.tostring().lastindexof(':')+1).Replace(' (fetch)','').trim()

.tostring().substring($originstr.lastindexof(':')+1).Replace(' (fetch)','').trim()


$res[0].RelativePath($pwd).replace('\','/')
#>

<#
$baseurl = 'https://github.com/'
$originstr = (git remote -v|Select-String 'origin.*fetch'|Select-Object -First 1).tostring()
$repofrag = $originstr.tostring().tostring().substring($originstr.lastindexof(':')+1).Replace(' (fetch)','').replace('.git','').trim()
#>

function Get-IfdefUrl{
    [cmdletbinding()]
    param(
        [string[]]$path = ($pwd),
        [string]$baseUrl = 'https://github.com/'
    )
    process{
        foreach($p in $path){
            try{
                Push-Location
                Set-Location $p
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
        [string[]]$path = ($pwd),
        [int]$context = 5
    )
    process{
        foreach($p in $path){
            if(-not (Test-Path $p)){
                'not found [{0}]' -f $p | Write-Warning
                continue
            }
            try{
                Push-Location
                Set-Location $p
                $branchName = ((git branch|Select-String '^\*').tostring().substring(2).trim())
                $baseurl = 'https://github.com/'
                $originstr = (git remote -v|Select-String 'origin.*fetch'|Select-Object -First 1).tostring()
                $repofrag = $originstr.tostring().tostring().substring($originstr.lastindexof(':')+1).Replace(' (fetch)','').replace('.git','').trim()
                Get-ChildItem .\ *.cs -Recurse -File|select-string '#if' -SimpleMatch -Context $context|%{ 
                    '{0}{1}/blob/{2}/{3}#L{4}' -f $baseurl,$repofrag,$branchName, ($_.RelativePath($pwd).replace('\','/')),$_.LineNumber
                    "$_`r`n"
                }
            }
            finally{
                Pop-Location
            }
        }
    }
}

function Get-RepoUrl{
    [cmdletbinding()]
    param(
        [string[]]$path
    )
    process{
        foreach($p in $path){
            if(-not (Test-Path $p)){
                'not found [{0}]' -f $p | Write-Warning
                continue
            }

            try{
                Push-Location | Out-Null
                Set-Location $p
                $originstr = (git remote -v|Select-String 'origin.*fetch'|Select-Object -First 1).tostring()
                if($originstr.Contains('https://')){
                    $originstr.substring($originstr.IndexOf('https://')).replace('(fetch)','').trim()
                }
                else{
                    $repofrag = $originstr.substring($originstr.lastindexof(':')+1).Replace(' (fetch)','').replace('.git','').trim()
                    '{0}{1}' -f $baseurl,$repofrag,$branchName
                }
            }
            finally{
                Pop-Location | Out-Null
            }
        }
    }
}

Function Get-StringHash{
    [cmdletbinding()]
    param(
        [String] $text,
        $HashName = "MD5"
    )
    process{
        $sb = New-Object System.Text.StringBuilder
        [System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($text))|%{
                [Void]$sb.Append($_.ToString("x2"))
            }
        $sb.ToString()
    }
}

function CloneRepo{
    [cmdletbinding()]
    param(
        [string[]]$url,
        [string]$rootDir = (Join-Path $env:LOCALAPPDATA 'xcompile\gitrepos')
    )
    process{
        if(-not (Test-Path $rootDir)){
            New-Item -Path $rootDir -ItemType Directory | Write-Verbose
        }
        foreach($u in $url){
            if(-not ([string]::IsNullOrWhiteSpace($u))){
                try{
                    Push-Location | Out-Null
                    $urlhash = (Get-StringHash $u)
                    $finalDest = (Join-Path $rootDir $urlhash)
                    
                    if(-not (Test-Path $finalDest)){
                        New-Item -Path $finalDest -ItemType Directory | Out-Null
                        Set-Location $finalDest | Out-Null
                        # https://github.com/dahlbyk/posh-git/issues/109#issuecomment-21638678
                        git clone $url $finalDest 2>&1 | % { $_.ToString() } | Out-Null
                    }
                    
                    $finalDest
                }
                finally{
                    Pop-Location | Out-Null
                }
            }
        }
    }
}

<#
[string[]]$paths = 'C:\Data\mycode\xunit',
                    'C:\data\mycode\Newtonsoft.Json',
                    'C:\data\mycode\dapper-dot-net',
                    'C:\data\mycode\AutoMapper',
                    'c:\data\mycode\EntityFramework',
                    'c:\data\mycode\Scaffolding',
                    'c:\data\mycode\log4net',
                    'c:\data\mycode\MVVMCross'
#Get-Ifdef -path $paths -context 10
#Get-IfdefUrl -path $paths
#Get-Ifdef -path 'c:\data\mycode\MVVMCross'
#Get-RepoUrl -path 'c:\data\mycode\MVVMCross','C:\data\mycode\MvvmCross2'
#CloneRepo -url git@github.com:sayedihashimi/riddlerps.git
#>