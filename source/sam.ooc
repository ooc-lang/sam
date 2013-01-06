
import structs/[ArrayList, HashMap]
import io/[File, FileReader]
import os/[Process, ShellUtils, Env]
import text/StringTokenizer

main: func (args: ArrayList<String>) {
    s := Sam new()
    s parseArgs(args)
}

Sam: class {

    home: File

    parseArgs: func (args: ArrayList<String>) {
        home = File new(args[0]) getAbsoluteFile() parent()

        if (args size <= 1) {
            usage()
            exit(1)
        }

        command := args[1]

        try {
            runCommand(command, args)
        } catch (e: Exception) {
            log("We've had errors: %s" format(e message))
        }
    }

    runCommand: func (command: String, args: ArrayList<String>) {
        match (command) {
            case "update" =>
                update()
            case "get" =>
                get(getUseFile(args))
            case "status" =>
                status(getUseFile(args))
            case =>
                log("Unknown command: %s" format(command))
                usage()
                exit(1)
        }
    }

    usage: func {
        log("Usage: sam [update|get|status]")
    }

    update: func {
        GitRepo new(home path) pull()
    }

    get: func (useFile: UseFile) {
        if (useFile deps empty?()) {
            log("%s has no dependencies! Bailing out Greece." format(useFile name))
            return
        }

        pp := ActionPool new(this, ActionType GET)
        for (dep in useFile deps) {
            pp add(useFile name, dep)
        }
        pp run()
    }

    status: func (useFile: UseFile) {
        if (useFile deps empty?()) {
            log("%s has no dependencies! Bailing out Greece." format(useFile name))
            return
        }

        pp := ActionPool new(this, ActionType STATUS)
        for (dep in useFile deps) {
            pp add(useFile name, dep)
        }
        pp run()
    }

    getUseFile: func (args: ArrayList<String>) -> UseFile {
        if (args size > 2) {
            UseFile new(args[2])
        } else {
            firstUse := firstUseFilePath()
            if (firstUse) {
                UseFile new(firstUse)
            } else {
                log("No .use file specified and none found in current directory. Sayonara!")
                exit(1)
            }
        }
    }

    firstUseFilePath: func -> String {
        children := File new(".") getChildren()
        for (c in children) {
            if (c name() endsWith?(".use")) {
                return c getPath()
            }
        }
        null
    }

    log: func (s: String) {
        "%s" printfln(s)
    }
    
}

UseFile: class {

    path: String
    name: String

    props := HashMap<String, String> new()
    deps := ArrayList<String> new()

    init: func (=path) {
        f := File new(path)
        name = f name()[0..-5]

        parse()
    }

    find: static func (name: String) -> This {
        dirs := File new(GitRepo oocLibs()) getChildren()
        fileName := "%s.use" format(name)

        for (dir in dirs) {
            for (child in dir getChildren()) {
                if (child name() == fileName) {
                    return This new(child getPath())
                }
            }
        }

        null
    }

    parse: func {
        PropReader new(path, props)

        // parse deps
        requires := props get("Requires")
        if (requires) {
            deps addAll(requires split(',', false) map (|dep| dep trim(" \t")))
        }
    }

}

PropReader: class {

    init: func (path: String, props: HashMap<String, String>) {
        fr := FileReader new(path)

        while (fr hasNext?()) {
            line := fr readLine() trim("\t ")

            if (line startsWith?('#') || line empty?()) {
                continue
            }

            tokens := line split(':', false)
            if (tokens size <= 1) {
                continue
            }

            key := tokens removeAt(0)
            value := tokens join(":")
            props put(key trim("\t "), value trim("\t "))
        }

        fr close()
    }

}

GitException: class extends Exception {
    
    init: super func

}

GitRepo: class {

    GIT_PATH: static String = null
    OOC_LIBS: static String = null

    dir: String
    url: String

    init: func (=dir, =url) {
        assert (dir != null)
    }

    init: func ~noUrl (.dir) {
        init(dir, "")
    }
    
    printOutput: func (output: String) {
        output split('\n', false) \
               map(|line| line trim("\t ")) \
               filter(|line| !line empty?()) \
               map(|line| " > " + line) \
               join("\n") \
               println()
    }

    pull: func {
        p := Process new([gitPath(), "pull"])
        p setCwd(dir)
        (output, exitCode) := p getOutput()
        printOutput(output)
        
        if (exitCode != 0) {
            GitException new("Failed to pull repository in %s" format(dir))
        }
    }

    clone: func {
        log("Cloning %s into %s" format(url, dir))
        log("J/k, we don't know how to do that yet...")
    }

    status: func {
        p := Process new([gitPath(), "status", "--short"])
        p setCwd(dir)
        (output, exitCode) := p getOutput()
        printOutput(output)
        
        if (exitCode != 0) {
            GitException new("Failed to get status of repository %s" format(dir))
        }
    }

    exists?: func -> Bool {
        File new(dir) exists?()
    }

    gitPath: static func -> String {
        if (!GIT_PATH) {
            GIT_PATH = ShellUtils findExecutable("git", true) getPath()
        }
        GIT_PATH
    }

    oocLibs: static func -> String {
        if (!OOC_LIBS) {
            OOC_LIBS = Env get("OOC_LIBS")
            if (!OOC_LIBS) {
                GitException new("$OOC_LIBS environment variable not defined! I'm outta here.") throw()
            }
            if (!(File new(OOC_LIBS) exists?())) {
                GitException new("$OOC_LIBS is set to %s, which doesn't exist. Ciao!" format(OOC_LIBS)) throw()
            }
        }
        OOC_LIBS
    }

    dirName: static func (gitUrl: String) -> String {
        if (!gitUrl endsWith?(".git")) {
            GitException new("Invalid git url: %s" format(gitUrl)) throw()
        }

        // trim '.git', get part before '/'
        dirName := gitUrl[0..-5] split('/') last()
        dirName
    }

    log: func (s: String) {
        "%s" printfln(s)
    }

}

SamException: class extends Exception {
    
    init: super func

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
        sam log("Processing %s (required by %s)" format(name, parent))

        f := Formula new(sam, name)
        url := f origin

        dirName := GitRepo dirName(url)
        repo := GitRepo new(File new(GitRepo oocLibs(), dirName) getPath(), url)

        doGet := func {
            if (repo exists?()) {
                repo pull()
            } else {
                repo clone()
            }

            useFile := UseFile find(name)
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
                sam log("Repository %s doesn't exist!" format(repo dir))
                return
            }

            useFile := UseFile find(name)
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

Formula: class {

    sam: Sam
    name, path: String

    origin: String

    props := HashMap<String, String> new()

    init: func (=sam, =name) {
        file := File new(File new(sam home, "library"), "%s.yml" format(name))
        path = file getPath()

        if (!file exists?()) {
            SamException new("Unknown formula: %s (tried %s)" format(name, path)) throw()
        }

        parse()
    }

    parse: func {
        PropReader new(path, props)

        if (!props contains?("Origin")) {
            SamException new("Malformed formula (doesn't contain Origin): %s" format(path)) throw()
        }

        origin = props get("Origin")
    }

}


