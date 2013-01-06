## sam

sam keep your ooc repos up-to-date. It allows you to get all the
dependencies for a project.

It also allows you, at one glance, to check if you've committed
all your latest changes in dependent repos.

### Building & Installing

sam has no dependencies, apart from rock itself. Get it [from GitHub](
https://github.com/nddrylliog/rock/#rock) and you'll be golden.

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

  * `sam update`: get the freshest formulas from sam git
  * `sam get [USEFILE]`: install and/or upgrade all dependencies
    listed in the given .use file. If no .use file is given, sam
    will take the first one in the current directory.
  * `sam status [USEFILE]`: displays the status of all the
    dependencies listed in the given .use file. Behaves like
    get in case no .use file is specified.
  * `sam promote [USEFILE]`: replace a read-only GitHub url (https/git)
    with a read-write GitHub url (ssh)

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

