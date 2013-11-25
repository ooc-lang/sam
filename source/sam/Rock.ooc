
// sdk
import structs/[ArrayList, List, HashMap]
import io/[File, FileReader]
import os/[Process, ShellUtils, Env, Pipe, Terminal]
import text/StringTokenizer

// ours
import sam/[CLITool]

Rock: class extends CLITool {

    ROCK_PATH: static String = null

    init: func (=dir) {
        assert (dir != null)
    }

    clean: func {
        p := Process new([rockPath(), "-x"])
        p setCwd(dir)

        launch(p, "Failed to run rock -x in %s" format(dir))
    }

    compile: func (args: List<String> = null) -> (String, Int) {
        rockArgs := [rockPath()] as ArrayList
        if (args) {
            rockArgs addAll(args)
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

