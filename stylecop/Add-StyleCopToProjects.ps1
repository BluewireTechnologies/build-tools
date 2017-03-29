param(
    [string]$rootPath = ""
)



function Make-RelativeTo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string]$referencePath,
        
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [string[]]$pipePaths,
        
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$paths
    )
    BEGIN {
        function _GetAncestry($p, [switch]$skipFile)
        {
            $p = Get-Item $p;
            if(!$p) { return; }
            function _List($i)
            {
                if(!$i.PSIsContainer)
                {
                    if(!$skipFile) { $i; }
                    $i = $i.Directory;
                }
                while($i) { $i; $i = $i.Parent; }
            }
            $l = _List $p;
            return $l[$l.Count..0];
        }
        
        $referencePathParts = _GetAncestry $referencePath -skipFile;
    }
    PROCESS {
        function _Relativise($path)
        {
            $pathParts = _GetAncestry $path;
            if($pathParts[0].Name -ne $referencePathParts[0].Name)
            {
                # Absolute.
                return (Get-Item $path).FullName.TrimEnd('\');
            }
            $i = 0;
            while($pathParts[$i].Name -eq $referencePathParts[$i].Name)
            {   
                $i++;
                if($i -gt $pathParts.Length -and $i -gt $referencePathParts.Length) 
                {
                    return "";
                }
            }
            
            $downPath = @($pathParts[$i..$pathParts.Length] | %{$_.Name}) -join '\';
            
            $upDistance = $referencePathParts.Length - $i;
            if($upDistance -gt 0)
            {
                $upPath = @(1..$upDistance | %{ '..' }) -join '\';
                if($downPath) { return $upPath + '\' + $downPath; }
                return $upPath;
            }
            return $downPath;
        }
        
        if($pipePaths.Length -gt 0)
        {
            $paths = $pipePaths;
        }
        foreach($_ in $paths)
        {
            if($_)
            {
                _Relativise $_;
            }
        }
    }
}

function Test()
{
    function Expect($expected, $block)
    {
        $actual = &$block;
        if($actual -eq $expected) { return ""; }
        
        "Expected '$expected', got '$actual': $($block)";
    }
    Expect "" { Make-RelativeTo c:\dev\epro c:\dev\epro }
    Expect "Epro.sln" { Make-RelativeTo c:\dev\epro\Epro.sln c:\dev\epro\Epro.sln }
    Expect "" { Make-RelativeTo c:\dev\epro\Epro.sln c:\dev\epro\ }
    Expect "Epro.sln" { Make-RelativeTo c:\dev\epro\ c:\dev\epro\Epro.sln }
    Expect ".." { Make-RelativeTo c:\dev\epro\ClientControls c:\dev\epro }
    Expect ".." { Make-RelativeTo c:\dev\epro\ClientControls\ClientControls.Common.props c:\dev\epro }
    Expect "..\..\.." { Make-RelativeTo c:\dev\epro\ClientControls\EproInk\Properties\AssemblyInfo.cs c:\dev\epro }
    Expect "ClientControls" { Make-RelativeTo c:\dev\epro c:\dev\epro\ClientControls }
    Expect "ClientControls" { Make-RelativeTo c:\dev\epro\Epro.sln c:\dev\epro\ClientControls }
    Expect "ClientControls\EproInk" { Make-RelativeTo c:\dev\epro\Epro.sln c:\dev\epro\ClientControls\EproInk }
    Expect "C:\dev\epro" { Make-RelativeTo e:\build c:\dev\epro\ }
}

function Find-ProjectFiles() # $containers...
{
    $containers = $args;
    foreach($container in $args)
    {
        foreach($containerPath in @(Resolve-Path "${rootPath}\${container}"))
        {
            Get-ChildItem -recurse -filter *.csproj $containerPath | %{ $_.FullName };
        }
    }
}

function Interpret-PathRelativeToFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string]$referenceFilePath,
        
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [string[]]$pipePaths,
        
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$paths
    )
    BEGIN {
        $file = Get-Item $referenceFilePath;
        $referenceDir = $file.Directory;
    }
    PROCESS {
        if($pipePaths.Length -gt 0)
        {
            $paths = $pipePaths;
        }
        foreach($_ in $paths)
        {
            $p = "${referenceDir}\$_";
            if(Test-Path $p) {
                (Get-Item $p).FullName;
            }
            else { $p; } # Don't canonicalise if nonexistent.
        }
    }
    END {}
}

filter Fixup-ProjectFileImports([string]$globalPropsFile, [string]$globalTargetsFile)
{
    $projectFile = Get-Item $_;
    if(!$projectFile) { return; } # Not present?!
   
    $projectFileXml = [xml](Get-Content $projectFile);
    
    $imports = @($projectFileXml.Project.Import);
    
    $unconditionalImports = $imports | where { -not $_.Condition; };
    $msImports = @($unconditionalImports | where { $_.Project -match "\bMicrosoft\b"; });
    $defaultImport = $msImports[0];
    if(!$defaultImport)
    {
        Write-Host -ForegroundColor Yellow "WARNING: Unable to find default import in $(${projectFile}.FullName)";
        return;
    }
    
    Write-Host "Processing $(${projectFile}.FullName)...";
    
    function _FindImport($fullPath)
    {
        @($unconditionalImports | where { $fullPath -eq $(Interpret-PathRelativeToFile $projectFile $_.Project) })[0];
    }
    
    function Insert-AroundDefaultImport([string]$before, [string]$after)
    {
        function _CreateImport($path)
        {
            $doc = $defaultImport.OwnerDocument;
            $importNode = $doc.CreateElement("Import",  $doc.DocumentElement.NamespaceURI);
            $importNode.SetAttribute("Project", $path);
            return $importNode;
        }
    
        if($before -and (Test-Path $before))
        {
            $existingBefore = _FindImport $before;
            if(!$existingBefore)
            {
                $relativeBefore = Make-RelativeTo $projectFile $before;
                $importNode = _CreateImport $relativeBefore;
                $defaultImport.ParentNode.InsertBefore($importNode, $defaultImport) | Out-Null;
                Write-Host "   Added $relativeBefore";
            }
        }
        
        if($after -and (Test-Path $after))
        {
            $existingAfter = _FindImport $after;
            if(!$existingAfter)
            {
                $relativeAfter = Make-RelativeTo $projectFile $after;
                $importNode = _CreateImport $relativeAfter;
                $defaultImport.ParentNode.InsertAfter($importNode, $defaultImport) | Out-Null;
                Write-Host "   Added $relativeAfter";
            }
        }
    }

    Insert-AroundDefaultImport $globalPropsFile $globalTargetsFile;
    
    foreach($import in $imports)
    {
        if($import.Project -match "\$\(") { continue; }
        if(Test-Path (Interpret-PathRelativeToFile $projectFile $import.Project)) { continue; }
        if($removeMissing)
        {
            $import.ParentNode.RemoveChild($import) | Out-Null;
            Write-Host "   Removed $(${import}.Project)";
        }
        else
        {
            Write-Host -ForegroundColor Yellow "   Missing file: $(${import}.Project)";
        }
    }
    
    $projectFileXml.Save($projectFile.FullName);
}

if(!$rootPath) 
{
    throw "No root path specified.";
}
if(-not (Test-Path $rootPath))
{
    throw "Root path does not exist: $rootPath";
}
$rootPath = $(Get-Item $rootPath).FullName;

$allProjects = Find-ProjectFiles .;
$allProjects | Fixup-ProjectFileImports "${rootPath}\StyleCopAnalyzers.props";
