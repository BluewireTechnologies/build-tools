# Standard Build

Components:
* Repository scripts, which should reside in the root.
* TeamCity version number calculation script. This needs to be set up to run before the MSBuild step which invokes TeamCity.Task.proj.

When using the `StandardVersionedBuildDotNet.xml` meta-runner (or the old `StandardVersionedBuild.xml` meta-runner, or for strange cases the `Set-VersionsFromGit.ps1` script directly):
* Repository root must contain .current-version file, containing only a major.minor version number.
  * If this is missing the script will quietly do nothing. The Version property will be left unset.
* Working directory is expected to be a valid Git repository with sufficient history to analyse topology. This means using 'agent-side checkout' in TeamCity terminology.
* The current state of the working copy is the revision for which the topological build number will be generated.

Versioning helpers:
* begin-new-version expects to be run from the repository root, and expects .current-version to already be present there.
  * For transitional commits which introduce this system, .current-version may be empty to retain existing versioning behaviour.

## Build Dependencies: `repository-v2/`

* Visual Studio 2019 (MSBuild Tools 16.0)
  * Later versions should work, but you must use the `StandardVersionedBuildDotNet.xml` meta-runner and your repository cannot contain legacy web projects.
* *Must* be using the PackageReference-style NuGet imports.
  * packages.config is no longer supported.
* Any NuGet packages which are not available from public feeds must be present in `nuget-local`.
* The only test framework currently supported is NUnit 3.
  * If running NUnit tests on .NET Framework, NUnit.ConsoleRunner of an appropriate version must be depended upon by at least one project.
    * NUnit.ConsoleRunner must be at least v3.
  * If running NUnit tests on .NET Core, each Core test project needs to reference the following packages:
    * Microsoft.NET.Test.Sdk
    * TeamCity.VSTest.TestAdapter
    * NUnit3TestAdapter
  * Test projects targeting both Core and Framework are supported.
* dotCover code coverage analysis is supported:
  * If at least one project references JetBrains.dotCover.CommandLineTools, that version of dotCover will be used.
  * When running under TeamCity, the build will fall back to using the dotCover provided by TeamCity. This may be too old to
    run .NET Core tests.
  * Locally-installed versions of dotCover *will not* be used automatically.

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

## Build.props

The standard build needs to be told which projects participate, by configuring Build.props.

.NET 5+ projects which build binaries should use `<PublishProjects>` instead of `<OutputBinaryProjects>`.

