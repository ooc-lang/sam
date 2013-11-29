
// sdk
import io/[File]
import structs/[ArrayList]

// sam
import sam/[Base, UseFile, Rock], sam

Checker: class {

    sam: Sam
    useFile, customUseFile: UseFile
    oocFile: File
    sourcePath: File
    cacheDir: File

    init: func (=sam, =oocFile) {
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

        args := [customUseFile file path, "-q", "--onlycheck"] as ArrayList<String>
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

