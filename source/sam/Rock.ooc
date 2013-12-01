
// sdk
import structs/[ArrayList, List, HashMap]
import io/[File, FileReader]
import os/[Process, ShellUtils, Env, Pipe, Terminal]
import text/StringTokenizer

// ours
import sam/[CLITool, Arguments]

Rock: class extends CLITool {

    args: Arguments
    ROCK_PATH: static String = null

    init: func (=args, =dir) {
        assert (dir != null)
    }

    clean: func {
        p := Process new([rockPath(), "-x"])
        p setCwd(dir)

        launch(p, "Failed to run rock -x in %s" format(dir))
    }

    compile: func (userArgs: List<String> = null) -> (String, Int) {
        rockArgs := ArrayList<String> new()

        rockArgs add(rockPath())
        if (userArgs) {
            rockArgs addAll(userArgs)
        }

        if (args hasLong?("rockargs")) {
            tokens := args longs["rockargs"] split(",")
            rockArgs addAll(tokens)
        }
        
        p := Process new(rockArgs)
        p setCwd(dir)
        message := "Failed to use rock to compile in %s" format(dir)
        (output, exitCode) := launch(p, message)
        (output, exitCode)
    }

    rockPath: static func -> String {
        if (!ROCK_PATH) {
            ROCK_PATH = ShellUtils findExecutable("rock", true) path
        }
        ROCK_PATH
    }

}

