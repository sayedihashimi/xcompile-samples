


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

function InternalGet-RelativePath{
    [cmdletbinding()]
    param(
        [Parameter(Position=0,Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$fromPath,

        [Parameter(Position=0,Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$toPath
    )
    process{
        $fromPathToUse = (Resolve-Path $fromPath).Path
        if( (Get-Item $fromPathToUse) -is [System.IO.DirectoryInfo]){
            $fromPathToUse += [System.IO.Path]::DirectorySeparatorChar
        }

        $toPathToUse = (Resolve-Path $toPath).Path
        if( (Get-Item $toPathToUse) -is [System.IO.DirectoryInfo]){
            $toPathToUse += [System.IO.Path]::DirectorySeparatorChar
        }

        [uri]$fromUri = New-Object -TypeName 'uri' -ArgumentList $fromPathToUse
        [uri]$toUri = New-Object -TypeName 'uri' -ArgumentList $toPathToUse

        [string]$relPath = $toPath
        # if the Scheme doesn't match just return toPath
        if($fromUri.Scheme -eq $toUri.Scheme){
            [uri]$relUri = $fromUri.MakeRelativeUri($toUri)
            $relPath = [Uri]::UnescapeDataString($relUri.ToString())

            if([string]::Equals($toUri.Scheme, [Uri]::UriSchemeFile, [System.StringComparison]::OrdinalIgnoreCase)){
                $relPath = $relPath.Replace([System.IO.Path]::AltDirectorySeparatorChar,[System.IO.Path]::DirectorySeparatorChar)
            }
        }

        if([string]::IsNullOrWhiteSpace($relPath)){
            $relPath = ('.{0}' -f [System.IO.Path]::DirectorySeparatorChar)
        }

        # return the result here
        $relPath
    }
}

# Heavily modified from: http://ss64.com/ps/zip.html / http://ss64.com/ps/zip.txt
Add-Type -As System.IO.Compression.FileSystem
function New-ZipFile {
	#.Synopsis
	#  Create a new zip file, optionally appending to an existing zip...
	[CmdletBinding()]
	param(
		# The path of the zip to create
		[Parameter(Position=0, Mandatory=$true)]
		$ZipFilePath,
 
		# Items that we want to add to the ZipFile
		[Parameter(Position=1, Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
		[Alias("PSPath","Item")]
		[string[]]$InputObject = $Pwd,
 
        [string]$rootFolder = $pwd,

        [string]$relpathinzip,

		# Append to an existing zip file, instead of overwriting it
		[Switch]$Append,
 
		# The compression level (defaults to Optimal):
		#   Optimal - The compression operation should be optimally compressed, even if the operation takes a longer time to complete.
		#   Fastest - The compression operation should complete as quickly as possible, even if the resulting file is not optimally compressed.
		#   NoCompression - No compression should be performed on the file.
		[System.IO.Compression.CompressionLevel]$Compression = "Optimal"
	)
	begin {
		# Make sure the folder already exists
		[string]$File = Split-Path $ZipFilePath -Leaf
		[string]$Folder = $(if($Folder = Split-Path $ZipFilePath) { Resolve-Path $Folder } else { $Pwd })
		$ZipFilePath = Join-Path $Folder $File
		# If they don't want to append, make sure the zip file doesn't already exist.
		if(!$Append) {
			if(Test-Path $ZipFilePath) { Remove-Item $ZipFilePath }
		}
		$Archive = [System.IO.Compression.ZipFile]::Open( $ZipFilePath, "Update" )
	}
	process {
		foreach($path in $InputObject) {
			foreach($item in Resolve-Path $path) {
				# Push-Location so we can use Resolve-Path -Relative
				# This will get the file, or all the files in the folder (recursively)
				foreach($file in Get-ChildItem $item -Recurse -File -Force | % FullName) {
					# Calculate the relative file path
                    $relative = InternalGet-RelativePath -fromPath $rootFolder -toPath $file
                    if(-not [string]::IsNullOrWhiteSpace($relpathinzip)){
                        $relative = $relpathinzip.TrimEnd('\').TrimEnd('/') + '\' + $relative.TrimEnd('\').TrimEnd('/') + '\'
                    }

					# Add the file to the zip
					$null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($Archive, $file, $relative, $Compression)
				}
			}
		}
	}
	end {
		$Archive.Dispose()
		Get-Item $ZipFilePath
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