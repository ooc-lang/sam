
// sdk
import structs/[ArrayList, List, HashMap]
import io/[File, FileReader]
import os/[Process, ShellUtils, Env, Pipe, Terminal]
import text/StringTokenizer

// ours
import sam/[Base, GitRepo, PropReader]

/**
 * Represents a parsed .use file
 */
UseFile: class {

    path: String
    name: String
    dir: String

    props := HashMap<String, String> new()
    deps := ArrayList<String> new()

    init: func (=path) {
        f := File new(path)
        name = f name[0..-5]
        dir = File new(path) getAbsoluteFile() parent path

        parse()
    }

    find: static func (name: String) -> This {
        dirs := File new(GitRepo oocLibs()) getChildren() filter(|f| f dir?())
        fileName := "%s.use" format(name)

        for (dir in dirs) {
            for (child in dir getChildren()) {
                if (child name == fileName) {
                    return This new(child path)
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

    repo: func -> GitRepo {
        GitRepo new(dir)
    }

    toString: func -> String {
        "%s:%s" format(name, repo() getBranch())
    }

    _: String { get {
        toString()
    } }

}

