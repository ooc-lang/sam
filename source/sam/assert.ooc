
expect: func ~str (given: String, expected: String) {
    if (given != expected) {
        "Fail! given #{given}, expected #{expected}"
        exit(1)
    }
}

expect: func ~int (given: Int, expected: Int) {
    if (given != expected) {
        "Fail! given #{given}, expected #{expected}"
        exit(1)
    }
}

describe: func (name: String, body: Func) {
    body()
    "Pass: #{name}" println()
}

