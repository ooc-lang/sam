
// sdk
import structs/[ArrayList, List, HashMap]
import io/[File, FileReader]
import os/[Process, ShellUtils, Env, Pipe, Terminal]
import text/StringTokenizer

// ours
import sam/[Base, Arguments]

CLITool: class {

    args: Arguments
    dir: String
    quiet := false
    fatal := true

    init: func (=args, =dir) {
        assert (dir != null)
    }

    printOutput: func (output: String) {
        formatted := output split('\n', false) \
                     map(|line| line trim("\t ")) \
                     filter(|line| !line empty?()) \
                     map(|line| " > " + line) \
                     join("\n") \
                     trim("\n")
        if (!formatted empty?()) {
            formatted println()
        }
    }

    launch: func (p: Process, message: String) -> (String, Int) {
        if (args shorts contains?("v")) {
            "$ #{p getCommandLine()}" println()
        }

        p stdErr = Pipe new()
        (output, exitCode) := p getOutput()

        if (!quiet) {
            printOutput(output)
        }

        if (fatal && exitCode != 0) {
            SamException new(message) throw()
        }

        (output, exitCode)
    }
}


AnyExecutable: class extends CLITool {

    file: File

    init: func (.args, .dir, =file) {
        super(args, dir)

        if (!file exists?()) {
            exe := File new(file path + ".exe")
            if (exe exists?()) {
              this file = exe
            } else {
              SamException new("Tried to launch nonexistent executable %s" format(file path)) throw()
            }
        }
    }

    run: func -> (String, Int) {
        p := Process new([file path])
        p setCwd(dir)

        message := "Failed to launch %s in %s" format(file name, dir)
        (output, exitCode) := launch(p, message)
        (output, exitCode)
    }

}

