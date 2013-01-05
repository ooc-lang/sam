
import structs/[ArrayList, HashMap]
import io/File

main: func (args: ArrayList<String>) {

    s := Sam new()
    s parseArgs(args)

}

Sam: class {

    home: File

    parseArgs: func (args: ArrayList<String>) {
        home = File new(args[0]) getAbsoluteFile() parent()

        if (args size <= 1) {
            log("Usage: sam [update|get|status]")
            exit(1)
        }

        match (args[1]) {
            case "update" =>
                update()
            case "get" =>
                get(getUseFile(args))
            case "status" =>
                status(getUseFile(args))
        }
    }

    update: func {
        log("Sam should update! Home = %s" format(home path))
    }

    get: func (useFile: UseFile) {
        log("Sam should 'get' from useFile %s!" format(useFile name))
    }

    status: func (useFile: UseFile) {
        log("Sam should 'status' from useFile %s!" format(useFile name))
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
        s println()
    }
    
}

UseFile: class {

    path: String
    name: String

    init: func (=path) {
        f := File new(path)
        name = f name()
    }

}

