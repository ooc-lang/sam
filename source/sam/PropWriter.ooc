
// sdk
import structs/[ArrayList, List, HashMap]
import io/[File, FileWriter]

/**
 * Writes .use files and sam formula files
 */
PropWriter: class {

    init: func (path: String, props: HashMap<String, String>) {
        fW := FileWriter new(path)

        props each(|key, value|
            fW write(key). write(": "). write(value). write('\n')
        )

        fW close()
    }

}
