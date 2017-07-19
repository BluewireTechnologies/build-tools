# Site Configuration Packages Build

Components:
* TeamCity build invocation script.

Build Dependencies:
* MSBuild
* Expects:
  * a Sites/ directory containing one directory per site package, which in turn contain a 'version' file with a version number in major.minor form,
  * a scripts/package.proj MSBuild file which takes three parameters: Site, OutputVersion, OutputDirectory.
* Working directory is expected to be a valid Git repository with sufficient history to analyse topology. This means using 'agent-side checkout' in TeamCity terminology.
* The current state of the working copy is the revision for which the topological build number will be generated.

## Setting up a new repository to use these

* The script in ci-teamcity/ may be used as a build step in your TeamCity build configuration.

