import Foundation

/// Implements Last-Write-Wins-Element-Dictionary as one kind of "Conflict Free Data Type" (CRDT).
/// More details can be found at https://bit.ly/2OnDLr1
///  Implementation is not thread-safe.
/// - Implementation is biased to removals, that is if when removing value for some key timestamps of add and removal are equal then element is
///     considered to be removed.
/// - Merge is biased to `self`, that is if both dictionaries contain the same key with equal timestamp then `self` prevails.
struct LWWElementDictionary<Value, T>: Equatable where Value: Equatable, T: TimestampProvider {
    
    typealias ValueWithTimestamp = (value: Value, timestamp: T.Timestamp)
    
    private var adds = [AnyHashable : ValueWithTimestamp]()
    
    /// - Note: there is no need to store values in `removal` dictionary and doing so improves effeciency
    ///         it terms of space.
    private var removalTimestamps = [AnyHashable : T.Timestamp]()
    private let timestampProvider: T
    
    /// The number of key-value pairs in dictionary.
    /// Time complixity of calculation is O(n).
    var count: Int {
        adds.reduce(into: 0) { (res, arg1) in
            let (key, (_, aTimestamp)) = arg1
            if let rTimestamp = removalTimestamps[key] {
                if rTimestamp < aTimestamp {
                    res += 1
                }
            }
            else {
                res += 1
            }
        }
    }
    
    /// All keys of the dictionary.
    /// Keys of the elements that are considered as removed are not listed.
    var keys: Set<AnyHashable> {
        adds.reduce(into: Set<AnyHashable>()) { (res, arg1) in
            let (key, (_, aTimestamp)) = arg1
            if let rTimestamp = removalTimestamps[key] {
                if rTimestamp < aTimestamp {
                    res.insert(key)
                }
            }
            else {
                res.insert(key)
            }
        }
    }
    
    init(timestampProvider: T) {
        self.timestampProvider = timestampProvider
    }
    
    /// - Returns value which was added with earliest timestamp and for which there was no removal with earlier timestamp.
    func value(forKey key: AnyHashable) -> Value? {
        guard let a = adds[key] else { return nil }
        if let rTimestamp = removalTimestamps[key] {
            if a.timestamp > rTimestamp {
                return a.value
            }
            else {
                return nil
            }
        }
        else {
            return a.value
        }
    }

    /// Updates the value stored in the dictionary for the given key, or adds a new key-value pair if the key does not exist.
    mutating func updateValue(_ value: Value, forKey key: AnyHashable) {
        let timestamp = timestampProvider.now()
        if let oldValue = adds[key] {
            if timestamp >= oldValue.timestamp {
                adds[key] = (value, timestamp)
            }
        }
        else {
            adds[key] = (value, timestamp)
        }
    }
    
    /// if there is already 'add' element in dictionary and  timestamps of 'add' and 'removal' are equal then the element is considered to have been removed.
    /// That is implementation is biased to removal.
    mutating func removeValue(forKey key: AnyHashable) {
        if let _ = value(forKey: key) {
            removalTimestamps[key] = timestampProvider.now()
        }
    }
    
    /// Merge is biased to `self`. That is if `other` contains the same key with equal timestamp then `self` prevails.
    mutating func merge(_ other: LWWElementDictionary) {
        adds.merge(other.adds) { (a, otherA) in (otherA.timestamp > a.timestamp ? otherA : a) }
        removalTimestamps.merge(other.removalTimestamps) { (timestamp, otherTimestamp) in
            (otherTimestamp > timestamp ? otherTimestamp : timestamp)
        }
    }
    
    static func == (lhs: LWWElementDictionary<Value, T>, rhs: LWWElementDictionary<Value, T>) -> Bool {
        guard lhs.count == rhs.count else { return false }
        for key in lhs.keys {
            if rhs.value(forKey: key) != lhs.value(forKey: key) {
                return false
            }
        }
        return true
    }
    
}
