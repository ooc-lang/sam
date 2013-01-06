## sam

sam keep your ooc repos up-to-date. It allows you to get all the
dependencies for a project.

It also allows you, at one glance, to check if you've committed
all your latest changes in dependent repos.

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
    there.

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

