# Fortran package manager (fpm) manifest reference

> **Important**
>
> The authorative manifest reference is available
> [here](https://github.com/fortran-lang/fpm/blob/master/manifest-reference.md).
> This document describes the current state of the the Haskell fpm manifest syntax.

The ``fpm.toml`` file for each project is called its *manifest*.
It is written using the [TOML] format.
Every manifest file consists of the following sections:

- [*name*](#project-name):
  The name of the project
- [*version*](#project-version):
  The version of the project
- [*license*](#project-license):
  The project license
- [*maintainer*](#project-maintainer):
  Maintainer of the project
- [*author*](#project-author):
  Author of the project
- [*copyright*](#project-copyright):
  Copyright of the project
- Target sections:
  - [*library*](#library-configuration)
    Configuration of the library target
  - [*executable*](#executable-targets)
    Configuration of the executable targets
  - [*test*](#test-targets)
    Configuration of the test targets
- Dependency sections:
  - [*dependencies*](#specifying-dependencies):
    Project library dependencies
  - [*dev-dependencies*](#development-dependencies):
    Dependencies only needed for tests


[TOML]: https://toml.io/


## Project name

The project name identifies the package and is used to refer to it.
It is used when listing the project as dependency for another package and the default name of the library and executable target.
Therefore, the project name must always be present.

*Example:*

```toml
name = "hello_world"
```


## Project version

The version number of the project is specified as string.
A standardized way to manage and specify versions is the [Semantic Versioning] scheme.

*Example:*

```toml
version = "1.0.0"
```

[Semantic Versioning]: https://semver.org


## Project license

The project license field contains the license identifier.
A standardized way to specify licensing information are [SPDX] identifiers.

*Examples:*

Projects licensed under the [GNU Lesser General Public License](https://www.gnu.org/licenses/lgpl-3.0-standalone.html), either version 3 or any later version, is specified as

```toml
license = "LGPL-3.0-or-later"
```

Dual licensed project under the [Apache license, version 2.0](http://www.apache.org/licenses/LICENSE-2.0) or the [MIT license](https://opensource.org/licenses/MIT) are specified as

```toml
license = "Apache-2.0 OR MIT"
```

[SPDX]: https://spdx.org/licenses/


## Project maintainer

Information on the project maintainer and means to reach out to them.

*Example:*

```toml
maintainer = "jane.doe@example.com"
```


## Project author

Information on the project author.

*Example:*

```toml
author = "Jane Doe"
```


## Project copyright

A statement clarifying the copyright status of the project.

*Example:*

```toml
copyright = "Copyright 2020 Jane Doe"
```


## Project targets

Every fpm project can define library, executable and test targets.
Library targets are exported and useable for other projects.


### Library configuration

Defines the exported library target of the project.
A library is generated if the source directory or include directory is found in a project.
The default source directory is ``src`` and can be modified in the *library* section using the *source-dir* entry.
Paths for the source directory are given relative to the project root and use ``/`` as path separator on all platforms.

*Example:*

```toml
[library]
source-dir = "lib"
```

#### Custom build script

Projects with custom build scripts can specify those in the *build-script* entry.
The custom build script will be executed when the library build step is reached.

*Example:*

```toml
[library]
build-script = "build.sh"
```

Build scripts written in ``make`` are automatically detected and executed with ``make``

```toml
[library]
build-script = "Makefile"
```


### Executable targets

Executable targets are Fortran programs defined as *executable* sections.
If no executable section is specified the ``app`` directory is searched for program definitions.
For explicitly specified executables the *name* entry must always be specified.
The source directory for each executable can be adjusted in the *source-dir* entry.
Paths for the source directory are given relative to the project root and use ``/`` as path separator on all platforms.
The source file containing the program body can be specified in the *main* entry.

Executables can have their own dependencies.
See [specifying dependencies](#specifying-dependencies) for more details.

*Example:*

```toml
[[ executable ]]
name = "app-name"
source-dir = "prog"
main = "program.f90"

[[ executable ]]
name = "app-tool"
[executable.dependencies]
helloff = { git = "https://gitlab.com/everythingfunctional/helloff.git" }
```

Specifying many separate executables can be done by using inline tables for brevity instead

```toml
executable = [
  { name = "a-prog" },
  { name = "app-tool", source-dir = "tool" },
]
```


### Example targets

Example applications for a project are defined as *example* sections.
If no example section is specified the ``example`` directory is searched for program definitions.
For explicitly specified examples the *name* entry must always be specified.
The source directory for each example can be adjusted in the *source-dir* entry.
Paths for the source directory are given relative to the project root and use ``/`` as path separator on all platforms.
The source file containing the program body can be specified in the *main* entry.

Examples can have their own dependencies.
See [specifying dependencies](#specifying-dependencies) for more details.

*Example:*

```toml
[[ example ]]
name = "demo-app"
source-dir = "demo"
main = "program.f90"

[[ example ]]
name = "example-tool"
[example.dependencies]
helloff = { git = "https://gitlab.com/everythingfunctional/helloff.git" }
```


### Test targets

Test targets are Fortran programs defined as *test* sections.
They follow similar rules as the executable targets.
If no test section is specified the ``test`` directory is searched for program definitions.
For explicitly specified tests the *name* entry must always be specified.
The source directory for each test can be adjusted in the *source-dir* entry.
Paths for the source directory are given relative to the project root and use ``/`` as path separator on all platforms.
The source file containing the program body can be specified in the *main* entry.

Tests can have their own dependencies.
See [specifying dependencies](#specifying-dependencies) for more details.

*Example:*

```toml
[[ test ]]
name = "test-name"
source-dir = "testing"
main = "tester.F90"

[[ test ]]
name = "tester"
[test.dependencies]
helloff = { git = "https://gitlab.com/everythingfunctional/helloff.git" }
```


## Specifying dependencies

Dependencies can be declared in the *dependencies* table in the manifest root or the [*executable*](#executable-targets) or [*test*](#test-targets) sections.
When declared in the manifest root the dependencies are exported with the project.


### Local dependencies

To declare local dependencies use the *path* entry.

```toml
[dependencies]
my-utils = { path = "utils" }
```

Local dependency paths are given relative to the project root and use ``/`` as path separator on all platforms.


### Dependencies from version control systems

Dependencies can be specified by the projects git repository.

```toml
[dependencies]
toml-f = { git = "https://github.com/toml-f/toml-f" }
```

To use a specific upstream branch declare the *branch* name with

```toml
[dependencies]
toml-f = { git = "https://github.com/toml-f/toml-f", branch = "master" }
```

Alternatively, reference tags by using the *tag* entry

```toml
[dependencies]
toml-f = { git = "https://github.com/toml-f/toml-f", tag = "v0.2.1" }
```

To pin a specific revision specify the commit hash in the *rev* entry

```toml
[dependencies]
toml-f = { git = "https://github.com/toml-f/toml-f", rev = "2f5eaba" }
```

For more verbose layout use normal tables rather than inline tables to specify dependencies

```toml
[dependencies]
[dependencies.toml-f]
git = "https://github.com/toml-f/toml-f"
rev = "2f5eaba864ff630ba0c3791126a3f811b6e437f3"
```

### Development dependencies

Development dependencies allow to declare *dev-dependencies* in the manifest root, which are available to all tests but not exported with the project.
