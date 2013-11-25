
// sdk
import structs/[ArrayList, List, HashMap]
import io/[File, FileReader]
import text/StringTokenizer

/**
 * Reads .use files and sam formula files
 */
PropReader: class {

    init: func (path: String, props: HashMap<String, String>) {
        fr := FileReader new(path)

        while (fr hasNext?()) {
            line := fr readLine() trim("\t ")

            if (line startsWith?('#') || line empty?()) {
                continue
            }

            tokens := line split(':', false)
            if (tokens size <= 1) {
                continue
            }

            key := tokens removeAt(0)
            value := tokens join(":")
            props put(key trim("\t "), value trim("\t "))
        }

        fr close()
    }

}

