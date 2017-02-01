# Standard Build

Components:
* Repository scripts, which should reside in the root.
* TeamCity version number calculation script. This needs to be set up to run before the MSBuild step which invokes TeamCity.Task.proj.

Build Dependencies:
* Visual Studio 2015 (MSBuild Tools 14.0)
  * Later versions may work, but not yet tested.
* Expects packages/ and its content to be present in the repository. Package restore is *not* supported and probably won't be.
* If building NuGet packages, expects packageable projects to use MsBuild.NuGet.Pack
  * Mostly works with v1.6.1, but semantic tags were excluded from package names.
  * v2.0.0 introduces breaking change to NugetPackageTargetDir. Waiting on pull request to work around this.
* If running NUnit tests, expects NUnit.Console of an appropriate version to be installed in packages/.
  * NUnit.Console must be at least v3.

When using Set-VersionsFromGit.ps1 (or the StandardVersionedBuild.xml meta-runner):
* Repository root must contain .current-version file, containing only a major.minor version number.
  * If this is missing the script will quietly do nothing. The Version property will be left unset.
* Working directory is expected to be a valid Git repository with sufficient history to analyse topology. This means using 'agent-side checkout' in TeamCity terminology.
* The current state of the working copy is the revision for which the topological build number will be generated.

Versioning helpers:
* begin-new-version expects to be run from the repository root, and expects .current-version to already be present there.
  * For transitional commits which introduce this system, .current-version may be empty to retain existing versioning behaviour.

## Setting up a new repository to use these

* All files in repository/ should go in the root of the repository.
* All files in versioning-auto/ may go in the root of the repository, if you need auto-versioning and use a POSIX-like shell.
* The scripts in ci-teamcity/ may be copied into early build steps in your TeamCity build configuration.

