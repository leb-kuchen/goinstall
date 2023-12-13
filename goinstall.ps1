#!/usr/bin/env pwsh
param(
    $version = "",
    $action = "",
    $arch = "amd64",
    $os = "linux",
    $ext = "tar.gz"
   
)
$ErrorActionPreference = "Stop"
function Get-Latest-Go-Version {
    param(
        [string]$url,
        [string]$versionRegex
    )
    $html = Invoke-WebRequest -Uri $url
    $match = $html.Content | Select-String -Pattern $versionRegex -AllMatches
    $latestVersion = $match.Matches | ForEach-Object { $_.Groups[1].Value } | Sort-Object { [Version]$_ } -Descending | Select-Object -First 1
    return $latestVersion
}

function Install-Go {
   if ($version -eq "" ){
        $version = Read-Host "go version"
    }
    if ($version.StartsWith("l")) {
        $regex = '<a[^>]*href="/dl/go(\d+(\.\d+)+)\.{0}-{1}\.{2}[^>]*>' -f $os, $arch, $ext
        $latest = Get-Latest-Go-Version  "https://go.dev/dl/" $regex
        $version = $latest
    }
    $download = "go$version.$os-$arch.$ext"
    $hash = "$download.sha256"
    $addr = "https://dl.google.com/go/"
    Invoke-WebRequest "$addr$download" -OutFile $download
    Invoke-WebRequest  "$addr$hash" -OutFile  $hash
    $cmp = Get-FileHash -Algorithm SHA256 $download
    if($cmp.Hash -ine (Get-Content $hash)) {
        throw "error verifying hash"
    }
    tar -xf $download
    sudo chown -R root:root ./go
    sudo mv -v go /usr/local
    $exp = @'
    $env:GOPATH = "$env:HOME/go"
    $env:PATH += ":/usr/local/go/bin:$env:GOPATH/bin"
'@
if (-not (Test-Path $PROFILE)) {
    New-Item -Path $PROFILE -ItemType File -Force
}
 $exp >> $PROFILE
 go version
}
function Remove-Go {
    sudo rm -rf /usr/local/go
}

function Update-Go {
    Remove-Go
    Install-Go

}
if ($action -eq "" ){
    $action = Read-Host "(u)pdate, (i)nstall, (r)remove go"
}

switch( $action.Trim().ToLower()[0] ){
    "u" {
        Update-Go
    }
    "i" {
        Install-Go
    }
    "r" {
        Remove-Go
    }
    Default {
        "no option"
    }
}



