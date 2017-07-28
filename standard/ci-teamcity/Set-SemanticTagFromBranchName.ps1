param(
    [string]$currentBranch,
    [string]$masterBranchSemanticTag,
    [string]$commitIdentifier,
    [int]$trimIdentifierLength = $null
)

Trap {
    Write-Host $error;
    Write-Host "Failed to determine version number.";
    exit 2;
}
$ErrorActionPreference = "Stop";

function Get-CommitId()
{
    if ($trimIdentifierLength -and $commitIdentifier.Length -gt $trimIdentifierLength) {
        return $commitIdentifier.Substring(0, $trimIdentifierLength);
    }
    return $commitIdentifier;
}

function Get-MasterBranchSemanticTag()
{
    return $masterBranchSemanticTag;
}

function Put-Parameter($name, $value)
{
    Write-Host "##teamcity[setParameter name='$name' value='$value']"
}

function Get-SemanticTag($lowercaseBranch, $commitId, $masterTag)
{
    if ($lowercaseBranch.StartsWith("canary/")) { return "canary"; }
    if ($lowercaseBranch.StartsWith("candidate/")) { return "rc"; }
    if ($lowercaseBranch.StartsWith("release/")) { return "release"; }
    if ($lowercaseBranch.Equals("master")) { return "${masterTag}"; }
    return "alpha.g${commitId}";
}

$commitId = Get-CommitId;
$masterTag = Get-MasterBranchSemanticTag;
$semanticTag = Get-SemanticTag $currentBranch.ToLower() $commitId $masterTag;

Put-Parameter 'system.SemanticTag' $semanticTag;
