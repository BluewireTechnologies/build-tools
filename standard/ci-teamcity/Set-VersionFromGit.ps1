param(
    [string]$workingRoot
)

Trap {
    Write-Host $error;
    Write-Host "Failed to determine version number.";
    exit 2;
}
$ErrorActionPreference = "Stop";

function Die([int]$code, [string]$error)
{
    Write-Host $error;
    exit $code;
}

if (-not (Test-Path "${workingRoot}")) { Die 4 "Working copy directory does not exist: ${workingRoot}"; }
$gitDir = "${workingRoot}\.git";
if (-not (Test-Path "${gitDir}")) { Die 4 "Not a Git repository: ${gitDir}"; }

function Invoke-Git()
{
    git -C "${workingRoot}" @args;
}

function Test-Tag([string]$tagName)
{
    Invoke-Git show-ref --verify --quiet "refs/tags/${tagName}" 2>&1 | Out-Null;
    return !!$?;
}

function Count-Revisions([string]$tagName)
{
    Invoke-Git rev-list "${majorMinor}..HEAD" --count;
    if (!$?) { Die 3 "git rev-list returned error code $LASTEXITCODE"; }
}

function Put-Parameter($name, $value)
{
    Write-Host "##teamcity[setParameter name='$name' value='$value']"
}


if (-not (Test-Path "${workingRoot}\.current-version")) { Die 0 "No .current-version file present. No attempt will be made to infer version number."; }

$majorMinor = $(get-content "${workingRoot}\.current-version");
if (-not $majorMinor) { Die 0 "The .current-version file is empty. No attempt will be made to infer version number."; }
$majorMinor = $majorMinor.Trim();
if (-not $majorMinor) { Die 0 "The .current-version file is empty. No attempt will be made to infer version number."; }

# Ensure that the version base tag is actually known to the local repository:
Invoke-Git fetch origin tag "${majorMinor}"

if (-not (Test-Tag "${majorMinor}")) { Die 2 "Could not find a tag with the name '${majorMinor}'." }

$buildNumber = $(Count-Revisions $majorMinor);
if(-not $buildNumber) { Die 2 "Could not determine topological build number for this version."; }

$m = $majorMinor -match '^(?<major>[0-9]+)\.(?<minor>[0-9]+)$';
if(!$m) { Die 2 "Unable to parse major.minor version number: '${majorMinor}'"; }

$version = [string]::Join('.', @(
    $matches['major'],
    $matches['minor'],
    $buildNumber
));

Put-Parameter "git.describe" $(Invoke-Git describe --tags --long --match "${majorMinor}")
Put-Parameter "git.seq" $buildNumber;
Put-Parameter "git.hash" $(Invoke-Git rev-parse --short HEAD)
Put-Parameter 'system.Version' $version;

Write-Host "##teamcity[buildNumber '$version']"
