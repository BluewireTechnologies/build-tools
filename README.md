# Standard Bluewire Build Scripts
*Canonical store of 'current' build techniques and standard patterns*

* *standard/:* The 'standard' Bluewire build scripts used for library packages and satellite services.
* *stylecop/:* StyleCop rules and build integration. Should be placed in the root of a repo, and the following added to project files immediately above the language import (eg. Microsoft.CSharp.targets):

```
  <Import Project="..\StyleCopAnalyzers.props" />
```
