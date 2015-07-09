
expect: func ~bool (expected: Bool, given: Bool) {
    if (given != expected) {
        "Fail! given #{given}, expected #{expected}" println()
        exit(1)
    }
}

expect: func ~ptr (expected: Pointer, given: Pointer) {
    if (given != expected) {
        "Fail! given %p, expected %p" printfln(given, expected)
        exit(1)
    }
}

expect: func ~float (expected: Float, given: Float) {
    if (given != expected) {
        "Fail! given #{given}, expected #{expected}" println()
        exit(1)
    }
}

expect: func ~char (expected: Char, given: Char) {
    if (given != expected) {
        "Fail! given #{given}, expected #{expected}" println()
        exit(1)
    }
}

expect: func ~str (expected: String, given: String) {
    if (given != expected) {
        "Fail! given #{given}, expected #{expected}" println()
        exit(1)
    }
}

expect: func ~int (expected: Int, given: Int) {
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

