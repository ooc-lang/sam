
// sdk
import structs/[ArrayList, List, HashMap]
import io/[File, FileReader]
import os/[Process, ShellUtils, Env, Pipe, Terminal]
import text/StringTokenizer

// ours
import sam/[Base, GitRepo, PropReader, PropWriter, Arguments]

/**
 * Represents a parsed .use file
 */
UseFile: class {

    args: Arguments
    file: File
    path ::= file path
    name: String
    dir: String

    props := HashMap<String, String> new()
    deps := ArrayList<String> new()

    init: func ~path (.args, .path) {
        init(args, File new(path))
    }

    init: func ~file (=args, =file) {
        name = file name[0..-5]
        dir = file getAbsoluteFile() parent path

        parse()
    }

    init: func ~clone (original: This) {
        file = File new(original file path)
        dir = original dir
        props = original props clone()
        deps = original deps clone()
    }

    find: static func (args: Arguments, name: String) -> This {
        dirs := File new(GitRepo oocLibs()) getChildren() filter(|f| f dir?())
        fileName := "%s.use" format(name)

        for (dir in dirs) {
            for (child in dir getChildren()) {
                if (child name == fileName) {
                    return This new(args, child path)
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

    write: func (=file) {
        dir = file parent path
        PropWriter new(path, props)
    }

    repo: func -> GitRepo {
        GitRepo new(args, dir)
    }

    toString: func -> String {
        "%s:%s" format(name, repo() getBranch())
    }

    _: String { get {
        toString()
    } }

    clone: func -> This {
        new(this)
    }

}

