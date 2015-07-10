
// sdk
import structs/[ArrayList]
import io/[File]
import os/[Terminal, Time, Env]
import text/[StringTokenizer, Shlex]

// ours
import sam, sam/[Base, CLITool, UseFile, Rock, Arguments]

/**
 * A series of tests
 */
TestSuite: class {

    sam: Sam
    args ::= sam args
    useFile: UseFile
    testDir, cacheDir: File
    testCases := ArrayList<TestCase> new()

    init: func (=sam, =useFile, =testDir, =cacheDir) {
        testDir = testDir getAbsoluteFile()

        if (!testDir exists?()) {
            sam log("Test directory '%s' doesn't exist. Our work here is done!", useFile name)
            return
        }
    }

    compileDeps: func {
        oocLibs := Env["OOC_LIBS"]
        if (!oocLibs) {
            sam log("$OOC_LIBS not set, bailing out")
            return
        }

        elements := oocLibs split(File pathDelimiter)
        for (el in elements) {
            sam log("Looking for sdk in #{el}")
            sdkFile := File new(el) findShallow("sdk.use", 2)

            if (sdkFile) {
                sam log("Compiling sdk from #{sdkFile path}...")
                rock := Rock new(args, cacheDir path)
                rock quiet = true
                rock fatal = false

                args := [sdkFile getAbsolutePath(), "-q"] as ArrayList<String>
                (compileOutput, compileExitCode) := rock compile(args)

                if (compileExitCode != 0) {
                    sam log("Failed to compile SDK separately :(")
                    sam log("Output:\n#{compileOutput}")
                    sam log("Continuing...")
                }
                return // all done!
            }
        }

        sam log("SDK not found, not precompiling...")
    }

    run: func {
        cacheDir rm_rf()
        cacheDir mkdirs()

        compileDeps()

        sam log("Running tests for %s", useFile _)

        if (sam args hasLong?("test")) {
            f := File new(sam args longs get("test"))
            if (!f exists?()) {
                raise("Test dir not found: #{f path}")
            }
            if (f dir?()) {
                testDir = f
            } else {
                doTest(f getAbsoluteFile())
                cleanCacheDir(cacheDir)
                println()
                return
            }
        }

        testDir walk(|f|
            if (f getName() toLower() endsWith?(".ooc")) {
                doTest(f getAbsoluteFile())
                cleanCacheDir(cacheDir)
            }

            true
        )
        println()
    }

    doTest: func (oocFile: File) {
        testCase := TestCase new(this, oocFile)
        testCases add(testCase)
        testCase run()

        times := "[%dms, %dms]" format(testCase compileTime, testCase execTime)
        prelude := times + " " + testCase name

        if (testCase pass) {
            if (testCase message != "") {
                sam ok(prelude + " (" + testCase message + ")", "PASS")
            } else {
                sam ok(prelude, "PASS")
            }
        } else {
            if (testCase message != "") {
                sam fail(prelude + " (" + testCase message + ")", "FAIL")
            } else {
                sam fail(prelude, "FAIL")
            }

            if (testCase output trim() != "") {
                sam log(testCase output)
            }
        }
    }

    report: func -> Int {
        totalTime := 0
        total := testCases size
        failed := 0
        passed := 0

        for (testCase in testCases) {
            if (testCase pass) {
                passed += 1
            } else {
                failed += 1
            }

            totalTime += testCase compileTime
            totalTime += testCase execTime
        }

        sam log("%d total tests, %d passed, %d failed, finished in %dms",
            total, passed, failed, totalTime)

        if (failed > 0) {
            return 1
        }

        0
    }

    cleanCacheDir: func (cacheDir: File) {
        File new(cacheDir, ".libs", "ooc", "test") rm_rf()
        File new(cacheDir, "rock_tmp", "ooc", "test") rm_rf()

        // needs globs to get rid of that one
        system("rm -rf #{cacheDir path}/.libs/test-*")
    }

}

TestCase: class {

    suite: TestSuite
    shouldfail := false
    shouldcrash := false
    name: String

    oocFile: File
    runTime := 0
    success := false

    // stages

    compileOutput := ""
    compileExitCode := -1
    compileTime := 0

    execArgs := ArrayList<String> new()
    execOutput := ""
    execExitCode := -1
    execTime := 0

    // status

    pass := false
    message := ""
    output := ""

    init: func (=suite, =oocFile) {
        parse()

        name = oocFile rebase(suite testDir) path
    }

    parse: func {
        // determine flags like shouldfail, shouldcrash, etc.
        lines := oocFile read() split("\n")
        for (l in lines) {
            if (l startsWith?("//!")) {
                command := l[3..-1] trim()
                match command {
                    case "shouldfail"  => shouldfail = true
                    case "shouldcrash" => shouldcrash = true
                    case =>
                        if (command startsWith?("cliargs")) {
                            rest := command[("cliargs" size + 1)..-1]
                            execArgs addAll(Shlex split(rest))
                        }
                }
            }
        }
    }

    run: func {
        compileTime = Time measure(||
            compile()
        )

        match compileExitCode {
            case 0 =>
                if (shouldfail) {
                    report(false, "compilation should have failed")
                    return
                }
            case 1 =>
                if (shouldfail) {
                    report(true, "")
                    return
                } else {
                    report(false, "compilation error - exit code: %d" format(compileExitCode))
                    output = compileOutput
                    return
                }
            case =>
                report(false, "compiler crashed ☃ exit code: %d" format(compileExitCode))
                output = compileOutput
                return
        }

        execTime = Time measure(||
            execute()
        )

        match execExitCode {
            case 0 =>
                if (shouldcrash) {
                    report(false, "test should have non-zero exit code")
                    return
                } else {
                    report(true, "")
                    return
                }
            case =>
                if (shouldcrash) {
                    report(true, "")
                    return
                } else {
                    report(false, "crashed - exit code: %d" format(execExitCode))
                    output = execOutput
                    return
                }
        }
    }

    compile: func {
        // Write out an ad-hoc .use file
        testUse := File new(suite cacheDir, "test.use")
        testUse write(
            "SourcePath: %s\n" format(oocFile parent path) +
            "Main: %s\n" format(oocFile name) +
            "BinaryPath: test\n"
        )

        rock := Rock new(suite args, suite cacheDir path)
        rock quiet = true
        rock fatal = false

        args := [testUse path, "-q", "--use=sam-assert"] as ArrayList<String>
        (compileOutput, compileExitCode) = rock compile(args)
    }

    execute: func {
        exec := AnyExecutable new(suite args, suite cacheDir path, File new(suite cacheDir, "test"))
        exec quiet = true
        exec fatal = false
        (execOutput, execExitCode) = exec run(execArgs)
    }

    report: func (=pass, =message) {
        // not much to do
    }

}

