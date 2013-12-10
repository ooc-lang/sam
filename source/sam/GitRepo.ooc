
// sdk
import structs/[ArrayList, List, HashMap]
import io/[File, FileReader]
import os/[Process, ShellUtils, Env, Pipe, Terminal]
import text/StringTokenizer

// ours
import sam/[CLITool]

GitRepo: class extends CLITool {

    GIT_PATH: static String = null
    OOC_LIBS: static String = null

    url: String

    init: func (.args, .dir, =url) {
        super(args, dir)
    }

    init: func ~noUrl (.args, .dir) {
        init(args, dir, "")
    }

    pull: func {
        p := Process new([gitPath(), "pull"])
        p setCwd(dir)
        (output, exitCode) := p getOutput()
        printOutput(output)
        
        if (exitCode != 0) {
            GitException new("Failed to pull repository in %s" format(dir)) throw()
        }
    }

    clone: func {
        p := Process new([gitPath(), "clone", url, dir])
        (output, exitCode) := p getOutput()
        printOutput(output)
        
        if (exitCode != 0) {
            GitException new("Failed to clone repository %s into %s" format(url, dir)) throw()
        }
    }

    getBranch: func -> String {
        p := Process new([gitPath(), "rev-parse", "--abbrev-ref", "HEAD"])
        p setCwd(dir)
        (output, exitCode) := p getOutput()
        
        if (exitCode != 0) {
            GitException new("Failed to get status of repository %s" format(dir)) throw()
        }
        return output trim(" \t\r\n")
    }

    status: func {
        p := Process new([gitPath(), "status", "--short"])
        p setCwd(dir)
        (output, exitCode) := p getOutput()
        printOutput(output)
        
        if (exitCode != 0) {
            GitException new("Failed to get status of repository %s" format(dir)) throw()
        }
    }

    promote: func {
        gitDir := File new(dir, ".git")
        if (!gitDir exists?()) {
            GitException new("%s is not a git repository" format(dir)) throw()
        }

        configFile := File new(gitDir, "config")
        if (!configFile exists?()) {
            GitException new("%s doesn't have a .git/config file" format(dir)) throw()
        }

        fr := FileReader new(configFile)

        foundOrigin := false

        while (fr hasNext?()) {
            line := fr readLine() trim("\t ")
            if (line startsWith?("[remote \"origin\"]")) {
                foundOrigin = true
                break
            }
        }

        if (!foundOrigin) {
            GitException new("No 'origin' remote in repo %s" format(dir)) throw()
        }

        url: String

        while (fr hasNext?()) {
            line := fr readLine() trim("\t ")
            if (line startsWith?("url = ")) {
                url = line split('=', false)[1] trim("\t ")
                break
            }
        }

        "Found url: %s" format(url) println()

        if (url startsWith?("git@github.com")) {
            "Already read-write! Maybe you don't have push access?" println()
            return
        }

        sshUrl: String

        // To understand the next part, read:
        // https://help.github.com/articles/which-remote-url-should-i-use

        // https urls are smart, they'll be either read-only or read-write
        // depending on your permissions. But they require special setup
        // so that you don't have to enter your username/password everytime.
        HTTPS_PREFIX := "https://github.com/"
        if (url startsWith?(HTTPS_PREFIX)) {
            repoName := url[HTTPS_PREFIX size..-1]
            if (repoName endsWith?(".git")) {
                // URLs with or without '.git' are valid, but we want it without
                repoName = repoName[0..-5]
            }

            // create an SSH url
            sshUrl = "git@github.com:%s.git" format(repoName)
        }

        // git urls are always read-only
        GIT_PREFIX := "git://"
        if (url startsWith?(GIT_PREFIX)) {
            repoName := url[GIT_PREFIX size..-1]
            if (repoName endsWith?(".git")) {
                // URLs with or without '.git' are valid, but we want it without
                repoName = repoName[0..-5]
            }

            // create an ssh url
            sshUrl = "git@github.com:%s.git" format(repoName)
        }

        fr close()
        content := configFile read() replaceAll(url, sshUrl)
        "Will replace your .git/config file with this: " println()
        "====================================" println()
        content println()
        "====================================" println()

        "Are you okay with that? [y/N]" println()
        inputReader := FileReader new(stdin)
        answer := inputReader readLine()
        inputReader close()

        if (answer startsWith?("y")) {
            configFile write(content)
            "Done!" println()
        } else {
            "Not doing anything." println()
        }
    }

    exists?: func -> Bool {
        File new(dir) exists?()
    }

    gitPath: static func -> String {
        if (!GIT_PATH) {
            GIT_PATH = ShellUtils findExecutable("git", true) path
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

GitException: class extends Exception {
    init: super func
    init: super func ~noOrigin
}

