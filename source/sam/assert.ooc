
expect: func ~float (given: Float, expected: Float) {
    if (given != expected) {
        "Fail! given #{given}, expected #{expected}" println()
        exit(1)
    }
}

expect: func ~char (given: Char, expected: Char) {
    if (given != expected) {
        "Fail! given #{given}, expected #{expected}" println()
        exit(1)
    }
}

expect: func ~str (given: String, expected: String) {
    if (given != expected) {
        "Fail! given #{given}, expected #{expected}" println()
        exit(1)
    }
}

expect: func ~int (given: Int, expected: Int) {
    if (given != expected) {
        "Fail! given #{given}, expected #{expected}" println()
        exit(1)
    }
}

describe: func (name: String, body: Func) {
    "Running #{name}..." println()
    body()
    "Pass" println()
}

