
// sdk
import structs/[ArrayList, List, HashMap]
import io/[File]

// ours
import sam/[Base, PropReader]

/**
 * Represents a parsed sam formula
 */
Formula: class {

    name, path: String

    origin: String

    props := HashMap<String, String> new()

    init: func (home: File, =name) {
        file := File new(File new(home, "library"), "%s.yml" format(name))
        path = file path

        if (!file exists?()) {
            SamException new("Unknown formula: %s (tried %s)" format(name, path)) throw()
        }

        parse()
    }

    parse: func {
        PropReader new(path, props)

        if (!props contains?("Origin")) {
            SamException new("Malformed formula (doesn't contain Origin): %s" format(path)) throw()
        }

        origin = props get("Origin")
    }

}

