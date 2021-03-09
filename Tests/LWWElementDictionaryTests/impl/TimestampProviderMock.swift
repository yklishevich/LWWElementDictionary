import LWWElementDictionary

class TimestampProviderMock: TimestampProvider {
    
    /// Value that will be returned next time when `now()` will be invoked.
    var counter = 0
    
    init(_ initialCounter: Int = 0) {
        self.counter = initialCounter
    }
    
    func now() -> Int {
        defer {
            counter += 1
        }
        return counter
    }
}
