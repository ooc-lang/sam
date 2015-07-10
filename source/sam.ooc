
// sdk
import structs/[ArrayList, List, HashMap]
import io/[File, FileReader]
import os/[Process, ShellUtils, Env, Pipe, Terminal]
import text/StringTokenizer

// ours
import sam/[Base, UseFile, GitRepo, CLITool, Formula, TestSuite,
    Rock, Checker, Arguments]

/**
 * Entry point
 */
main: func (args: ArrayList<String>) {
    s := Sam new()
    s parseArgs(args)
}

/**
 * Main program
 */
Sam: class {

    args: Arguments
    home ::= args home
    VERSION := "0.13.0"

    init: func

    parseArgs: func (commandLine: ArrayList<String>) {
        args = Arguments new(commandLine)

        if (args size < 1) {
            usage()
            exit(1)
        }

        command := args[0]

        try {
            runCommand(command, args)
        } catch (e: Exception) {
            log("We've had errors: %s", e message)
            exit(1)
        }
    }

    runCommand: func (command: String, args: Arguments) {
        match (command) {
            case "update" =>
                update()
            case "get" =>
                doSelf := !(args hasLong?("no-self"))
                get(getUseFile(args), doSelf)
            case "clone" =>
                withDeps := !(args hasLong?("no-deps"))
                clone(getRepoName(args), withDeps)
            case "status" =>
                status(getUseFile(args))
            case "promote" =>
                promote(getUseFile(args))
            case "test" =>
                test(args)
            case "check" =>
                check(args)
            case =>
                log("Unknown command: %s", command)
                usage()
                exit(1)
        }
    }

    usage: func {
        log("sam version %s", VERSION)
        log(" ")
        log("Usage: sam [update|get|status|promote|clone|test|check]")
        log(" ")
        log("Commands")
        log("  * update: update sam's grimoir of formulas")
        log("  * get [--no-self] [USEFILE]: clone and/or pull all dependencies")
        log("  * status [USEFILE]: display short git status of all dependencies")
        log("  * promote [USEFILE]: replace read-only github url with a read-write one")
        log("  * clone [--no-deps] [REPONAME]: clone a repository by its formula name")
        log("  * test [--test FILE.ooc] [USEFILE]: run all tests or a single specified test")
        log("  * check [--mode MODE] FILE.ooc: run a 'syntax', 'check' (default) or 'codegen'")
        log(" ")
        log("Note: All USEFILE arguments are optional. By default, the")
        log("first .use file of the current directory is used")
        log(" ")
        log("All commands that run rock (e.g. 'test') accept a --rockargs argument,")
        log("separated by commas.")
        log(" ")
        log("Copyleft 2013 Amos Wenger aka @nddrylliog")
    }

    update: func {
        log("Pulling repository %s", home path)
        GitRepo new(args, home path) pull()
        log("Recompiling sam")
        rock := Rock new(args, home path)
        rock clean()
        rock compile()
    }

    get: func (useFile: UseFile, doSelf: Bool) {
        if (doSelf) {
            log("[%s]", useFile name)
            useFile repo() pull()
        }

        if (useFile deps empty?()) {
            log("%s has no dependencies! Our work here is done.", useFile name)
            return
        }

        pp := ActionPool new(this, ActionType GET)
        for (dep in useFile deps) {
            pp add(useFile name, dep)
        }
        pp run()
    }

    clone: func (name: String, withDeps: Bool) {
        f := Formula new(this home, name)
        url := f origin
        repoPath := File new(GitRepo oocLibs(), f name) path
        repo := GitRepo new(args, repoPath, url)

        if(repo exists?()) {
            log("[%s:%s]", name, repo getBranch())
            log("Repository %s exists already. Pulling...", repo dir)
            repo pull()
        } else {
            log("[%s]", name)
            repo clone()
            log("Cloned %s into %s", url, repo dir)
        }

        if (withDeps) {
            get(UseFile new(args, "%s/%s.use" format(repo dir, name)), false)
        }
    }

    status: func (useFile: UseFile) {
        repo := useFile repo()
        log("[%s:%s]", useFile name, repo getBranch())
        repo status()

        if (useFile deps empty?()) {
            log("%s has no dependencies. Our work here is done.", useFile name)
            return
        }

        pp := ActionPool new(this, ActionType STATUS)
        for (dep in useFile deps) {
            pp add(useFile name, dep)
        }
        pp run()
    }

    check: func (args: Arguments) {
        checker := Checker new(args)
        ret := checker check()
        exit(ret)
    }

    test: func (args: Arguments) {
        useFile := getUseFile(args)

        useDir := File new(useFile dir)
        testDir := File new(useDir, "test")
        if (args size > 2) {
            testDir = File new(args[2])
        }
        cacheDir := File new(useDir, ".sam-cache")

        suite := TestSuite new(this, useFile, testDir getAbsoluteFile(), cacheDir)
        suite run()
        ret := suite report()
        exit(ret)
    }

    promote: func (useFile: UseFile) {
        log("Promoting %s", useFile name)

        useFile repo() promote()
    }

    getUseFile: func (args: Arguments) -> UseFile {
        if (args size > 1) {
            UseFile new(args, args[1])
        } else {
            firstUse := firstUseFilePath()
            if (firstUse) {
                UseFile new(args, firstUse)
            } else {
                log("No .use file specified and none found in current directory. Sayonara!")
                exit(1)
            }
        }
    }

    getRepoName: func (args: Arguments) -> String {
        if (args size > 1) {
            return args[1]
        }

        log("No repo name specified. Adios!")
        exit(1)
    }

    firstUseFilePath: func -> String {
        children := File new(".") getChildren()
        for (c in children) {
            if (c name endsWith?(".use")) {
                return c path
            }
        }
        null
    }

    log: func (s: String) {
        s println()
    }

    log: func ~var (s: String, args: ...) {
        s printfln(args)
    }

    ok: func (msg := "", type := " OK ") {
        Terminal setFgColor(Color green)
        text := "[%s] %s" format(type, msg)
        log(text)
        Terminal reset()
    }

    fail: func (msg := "", type := "FAIL") {
        Terminal setFgColor(Color red)
        text := "[%s] %s" format(type, msg)
        log(text)
        Terminal reset()
    }

}

ActionType: enum {
    GET
    STATUS
}

ActionTask: class {

    sam: Sam
    parent, name: String

    init: func (=sam, =parent, =name) {

    }

    process: func (pool: ActionPool) {
        f := Formula new(sam home, name)
        url := f origin

        dirName := GitRepo dirName(url)
        repoPath  := File new(GitRepo oocLibs(), dirName) path
        repo := GitRepo new(sam args, repoPath, url)
        repoName := name
        if (repo exists?()) {
          "%s:%s" format(name, repo getBranch())
        }

        sam log("[%s] (<= %s)", repoName, parent)

        doGet := func {
            if (repo exists?()) {
                repo pull()
            } else {
                repo clone()
            }

            useFile := UseFile find(sam args, name)
            if (!useFile) {
                SamException new("use file for %s not found after cloning/pulling" format(name)) throw()
            }

            for (dep in useFile deps) {
                pool add(name, dep)
            }
        }

        doStatus := func {
            if (repo exists?()) {
                repo status()
            } else {
                sam log("Repository %s doesn't exist!", repo dir)
                return
            }

            useFile := UseFile find(sam args, name)
            if (!useFile) {
                SamException new("use file for %s not found after cloning/pulling" format(name)) throw()
            }

            for (dep in useFile deps) {
                pool add(name, dep)
            }
        }

        match (pool actionType) {
            case ActionType GET =>
                doGet()
            case ActionType STATUS =>
                doStatus()
        }
    }

}

ActionPool: class {

    sam: Sam
    queued := HashMap<String, ActionTask> new()
    doing := ArrayList<ActionTask> new()
    actionType: ActionType

    init: func (=sam, =actionType) {
    }

    add: func (parent, name: String) {
        if (queued contains?(name)) {
            return
        }

        task := ActionTask new(sam, parent, name)
        queued put(name, task)
        doing add(task)
    }

    run: func {
        while (!doing empty?()) {
            current := doing removeAt(0)
            current process(this)
        }
    }

}

