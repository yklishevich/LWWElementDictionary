/// Provider of timestamps.
/// An implementation of this protocol is expected to be provided by middleware or in some other way.
/// As an example some global shared sequencer can be used for generating timestamps.
/// Generated timestams must be totally ordered.
public protocol TimestampProvider {
    associatedtype Timestamp: Comparable
    
    /// Returns totaly ordered timestams
    func now() -> Timestamp
}
