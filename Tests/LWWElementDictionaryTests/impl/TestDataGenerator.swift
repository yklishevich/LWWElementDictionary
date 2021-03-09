
func predeterminedKeyValuePairs(n: Int) -> [(String, String)] {
    var res = [(String, String)]()
    for i in 0..<n {
        res.append( (String(i), String(i)) )
    }
    return res
}

