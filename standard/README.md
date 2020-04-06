# Standard Build

Components:
* Repository scripts, which should reside in the root.
* TeamCity version number calculation script. This needs to be set up to run before the MSBuild step which invokes TeamCity.Task.proj.

When using Set-VersionsFromGit.ps1 (or the StandardVersionedBuild.xml meta-runner):
* Repository root must contain .current-version file, containing only a major.minor version number.
  * If this is missing the script will quietly do nothing. The Version property will be left unset.
* Working directory is expected to be a valid Git repository with sufficient history to analyse topology. This means using 'agent-side checkout' in TeamCity terminology.
* The current state of the working copy is the revision for which the topological build number will be generated.

Versioning helpers:
* begin-new-version expects to be run from the repository root, and expects .current-version to already be present there.
  * For transitional commits which introduce this system, .current-version may be empty to retain existing versioning behaviour.

## Build Dependencies: `repository-v2/`

* Visual Studio 2019 (MSBuild Tools 16.0)
  * Later versions may work, but not yet tested.
* *Must* be using the PackageReference-style NuGet imports.
  * packages.config is no longer supported.
* Any NuGet packages which are not available from public feeds must be present in `nuget-local`.
* If running NUnit tests, expects NUnit.ConsoleRunner of an appropriate version to be depended upon by at least one project.
  * NUnit.ConsoleRunner must be at least v3.

## Build Dependencies: `repository/`

* Visual Studio 2015 (MSBuild Tools 14.0) or 2017 (15.0)
  * Later versions *could possibly* work, but only by accident.
* Expects packages/ and its content to be present in the repository. Package restore is *not* supported and probably won't be.
* If building NuGet packages, expects packageable projects to use MsBuild.NuGet.Pack
  * Mostly works with v1.6.1, but semantic tags were excluded from package names.
  * v2.0.0 introduces breaking change to NugetPackageTargetDir. Waiting on pull request to work around this.
* If running NUnit tests, expects NUnit.ConsoleRunner of an appropriate version to be depended upon by at least one project.
  * NUnit.ConsoleRunner must be at least v3.

## Setting up a new repository to use these

* All files in repository/ XOR repository-v2/ should go in the root of the repository.
* All files in versioning-auto/ may go in the root of the repository, if you need auto-versioning and use a POSIX-like shell.
* The scripts in ci-teamcity/ may be copied into early build steps in your TeamCity build configuration.

