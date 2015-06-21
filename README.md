## sam

sam keep your ooc repos up-to-date. It allows you to get all the
dependencies for a project.

It also allows you, at one glance, to check if you've committed
all your latest changes in dependent repos.

### Building & Installing

sam has no dependencies, apart from rock itself. Get it [from GitHub](
https://github.com/nddrylliog/rock/#rock) and you'll be golden.

**Important note: sam requires rock 0.9.9 or greater. At the time of
this writing, it is not released yet and lives in the '99x' branch
of the rock repo. See [issue #11](https://github.com/nddrylliog/sam/issues/11) for details / instructions.**

For best results, clone sam in `$OOC_LIBS`. You should have write
access to that directory. For me, my usual choice is `~/Dev`.

To build sam, run:

```bash
rock -v
```

...from sam's directory. Since there's a `sam.use` file, rock knows
what to build. The result should be a `sam` or `sam.exe` executable,
depending on your platform.

Then, simply add sam to your PATH in your `~/.bashrc` or `~/.zshrc`.
For me, the line looks something like:

```bash
# Add sam to path
export PATH=$PATH:~/Dev/sam/
```

Then, source your rc file (or simply log out and in again) and, just to
make sure, run:

```bash
sam update
```

If you get no errors, then congrats! sam is properly installed, it found
its own home, your `$OOC_LIBS`, and can use your git install.

### Philosophy

Every dependency has a unique name, every unique name corresponds
to a single git repo, and every one of those git repos contains,
in the root directory, a .use file with the name of the dependency.

For example, for sdl2, we have

  * name: sdl2
  * repo: https://github.com/geckojsc/ooc-sdl2.git
  * repo structure:
      * README.md
      * sdl2.use
      * source

### Prerequisites

sam assumes a few things:

  * You must have `git` installed and in your $PATH
  * You must have the `$OOC_LIBS` environment variable set to
    a directory you can write to. sam will clone and/or pull repos
    there. It's also recommended to put sam in $OOC_LIBS

### Commands

  * `sam update`: update sam and its grimoir of formulas
  * `sam get [USEFILE]`: install and/or upgrade all dependencies
    listed in the given .use file. If no .use file is given, sam
    will take the first one in the current directory.
  * `sam status [USEFILE]`: displays the status of all the
    dependencies listed in the given .use file. Behaves like
    get in case no .use file is specified.
  * `sam promote [USEFILE]`: replace a read-only GitHub url (https/git)
    with a read-write GitHub url (ssh)
  * `sam clone [REPONAME]`: clone a repository by its formula name.
  * `sam test [USEFILE] [TESTDIR]`: run a test suite
  * `sam check [--mode=MODE] FILE.ooc`: run various checks (syntax, check, codegen)

### Testing

When the `sam test` command is ran, sam will attempt to compile and run every
.ooc file found in TESTDIR. By default, TESTDIR is the `test` directory found in
the specified repository.

Specifying a TESTDIR by hand might help with long test suite running times, by
only running a handful of tests as needed.

### Checking

The `sam check` command is my attempt to free myself from the 'classpath hell'
we have inherited from Java. Nowadays, most (if not all) projects have .use files
with SourcePaths. However, rock is not smart enough to find out which .use file
corresponds to a given .ooc file.

In the case of text editors, one might want to run checks on a given file. sam check
does exactly that. It'll go from parent folder to grandparent folders, finding
the .use file to which the .ooc file belongs.

There are three check modes:

  * `syntax`: the fastest - rock just parses a single file and reports syntax errors
    (missing braces, wrong string literal, invalid definitions, etc.)
  * `check`: a good compromise - rock parses and resolves the whole project. It
    reports everything `syntax` does, as well as type errors, unresolved symbols, etc.
    Much slower than `syntax`, but also much more useful.
  * `codegen`: some rare checks from rock are only ran when generating C code - this
    option is the all-in-one, shy of running a C compiler.

### Continuous Integration

sam can be used to run tests on continuous integration servers, such as
[Travis CI](https://travis-ci.org).

It is in use, notably, by [rock itself](https://travis-ci.org/nddrylliog/rock/builds).

An example .travis.yml is supplied here:

```yaml
before_script:
  - sudo apt-get update
  - sudo apt-get -y -qq install curl make libgc-dev
  - export PATH=$PATH:$PWD/rock/bin:$PWD/sam
  - export OOC_LIBS=$PWD
  - git clone --depth=1 git://github.com/nddrylliog/rock.git
  - git clone --depth=1 git://github.com/nddrylliog/sam.git
  - (cd rock && make -s quick-rescue)
  - (cd sam && rock -v)

script:
  - sam test
```

If your program requires a specific rock version (as opposed to the last stable
version), consider adding `-b xxx` in the rock clone command above, where
`xxx` is the rock branch corresponding to the version you're working with.

### FAQ

  * **Is sam inspired by mxcl/homebrew?** Yes, very much so. But sam's job is much simpler.

  * **Where's the binary distribution?** There's none. You're supposed to clone the repo
    yourself. This way 1) you can add your own formulas and later submit pull requests 2)
    we make sure you have git from step one.

  * **What does sam run on?** sam was tested on Windows 7/MSYS, OSX 10.7.2 and ArchLinux.
    It should run just about anywhere ooc code compiles and with git in the path.

  * **How do I write my own formulas?** Simply add your formula to `$SAM_HOME/library/yourformula.yml`.
    Look at other formulas to know how to write one.

  * **Where does the name sam come from?** It's frodo's buddy. Buy a book! Also it's short
    to type.

### Credits

sam was written by Amos Wenger in 2013, instead of working on his @OneGameAMonth entry.

