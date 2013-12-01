
// sdk
import io/[File]
import structs/[ArrayList]

// sam
import sam/[Base, UseFile, Rock, Arguments]

CheckMode: enum {
    SYNTAX
    CHECK
    CODEGEN
}

Checker: class {

    args: Arguments
    useFile, customUseFile: UseFile
    oocFile: File
    sourcePath: File
    cacheDir: File
    onlyparse := false

    mode := CheckMode CHECK

    init: func (=args) {
        if (args size < 2) {
            "Usage: sam check FILE.ooc" println()
            exit(1)
        }

        if (args hasLong?("mode")) {
            mode = match (args longs get("mode")) {
                case "syntax"  => CheckMode SYNTAX
                case "check"   => CheckMode CHECK
                case "codegen" => CheckMode CODEGEN
                case => mode
            }
        }

        oocFile = File new(args[1])
    }

    check: func -> Int {
        if (!oocFile exists?()) {
            "File not found: #{oocFile path}" println()
            return 1
        }

        locateUseFile()

        if (!useFile) {
            "Couldn't find usefile for: #{oocFile path}" println()
            return 1
        }

        prepareCache()

        if (!cacheDir exists?()) {
            "Couldn't create cache dir #{cacheDir path}" println()
            return 1
        }

        prepareCustomUseFile()

        if (!customUseFile file exists?()) {
            "Failed to create custom use file #{customUseFile file path}" println()
            return 1
        }

        launchRock()

        0
    }

    launchRock: func {
        rock := Rock new(cacheDir path)
        rock quiet = true
        rock fatal = false

        args := [customUseFile file path, "-q"] as ArrayList<String>
        match mode {
            case CheckMode SYNTAX  => args add("--onlyparse")
            case CheckMode CODEGEN => args add("--onlygen")
            case                   => args add("--onlycheck")
        }
        (compileOutput, compileExitCode) := rock compile(args)

        compileOutput print()
    }

    prepareCustomUseFile: func {
        customUseFile = useFile clone()
        customUseFile props put("SourcePath", sourcePath getAbsolutePath())
        customUseFile write(File new(cacheDir, "checker.use"))
    }

    prepareCache: func {
        cacheDir = File new(useFile dir, ".sam-cache")
        cacheDir mkdirs()
    }

    locateUseFile: func {
        dir := oocFile parent getAbsoluteFile()
        searchUseFile(dir, dir)
    }

    searchUseFile: func (dir, childDir: File) {
        dir children each(|f|
            match {
                case f file?() =>
                    if (f path toLower() endsWith?(".use")) {
                        uf := UseFile new(f path)
                        sp := uf props get("SourcePath")
                        if (sp) {
                            dir2 := File new(dir, sp)

                            if (dir2 getAbsolutePath() == childDir path) {
                                useFile = uf
                                sourcePath = dir2
                                return
                            }
                        }
                    }
            }
        )

        if (useFile) {
            // already found
            return
        }

        parent := dir parent
        if (parent && parent dir?()) {
            searchUseFile(parent, dir)
        }
    }

}

