__This repository archives the legacy Haskell implementation of fpm and is not under active development.__

__See [fortran-lang/fpm](https://github.com/fortran-lang/fpm) for the active fpm implementation__

# Fortran Package Manager - Haskell

Fortran Package Manager (fpm) is a package manager and build system for Fortran.
Its key goal is to improve the user experience of Fortran programmers.
It does so by making it easier to build your Fortran program or library, run the
executables, tests, and examples, and distribute it as a dependency to other
Fortran projects.
Fpm's user interface is modeled after [Rust's Cargo](https://doc.rust-lang.org/cargo/),
so if you're familiar with that tool, you will feel at home with fpm.
Fpm's long term vision is to nurture and grow the ecosystem of modern Fortran
applications and libraries.


## Building fpm-haskell

### Install Haskell

To install **Haskell Stack**, follow these [instructions](https://docs.haskellstack.org/en/stable/install_and_upgrade/),
users without superuser (admin) permissions should follow the [manual installation](https://docs.haskellstack.org/en/stable/install_and_upgrade/#manual-download_2) procedure.

### Download this repository

```bash
git clone https://github.com/fortran-lang/fpm-haskell
cd fpm
```

### Build and Test fpm

Build fpm using:
```bash
stack build
```
To test:
```bash
stack test
```
To install:
```bash
stack install
```

On Linux, the above command installs `fpm` to `${HOME}/.local/bin`.

## Usage

### Creating a new project

Creating a new fpm project is as simple as running the command `fpm new project_name`.
This will create a new folder in your current directory with the following contents
and initialized as a git repository.

* `fpm.toml` with your project's name and some default standard meta-data
* `README.md` with your project's name
* `.gitgnore`
* `src/project_name.f90` with a simple hello world subroutine
* `app/main.f90` (if `--with-executable` flag used) a program that calls the subroutine
* `test/main.f90` (if `--with-test` flag used) an empty test program

## Building your Fortran project with fpm

fpm understands the basic commands:

* `fpm build` - build your library, executables and tests
* `fpm run` - run executables
* `fpm test`- run tests

The command `fpm run` can optionally accept the name of the specific executable
to run, as can `fpm test`; like `fpm run specifc_executable`. Command line
arguments can also be passed to the executable(s) or test(s) with the option
`--args "some arguments"`.

See additional instructions in the [Packaging guide](PACKAGING.md).