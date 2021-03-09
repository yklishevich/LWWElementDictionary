import XCTest
@testable import LWWElementDictionary

class LWWElementDictionaryTest: XCTestCase {
    
    private let timestampProvider = TimestampProviderMock()
    private var lwwDictionary: LWWElementDictionary<String, TimestampProviderMock>!

    override func setUpWithError() throws {
        lwwDictionary = LWWElementDictionary(timestampProvider: timestampProvider)
    }

    override func tearDownWithError() throws {
        lwwDictionary = nil
    }
    
    func test_valueForKey_addSomeValue_returnsThisValue() {
        lwwDictionary.updateValue("value", forKey: "key")
        XCTAssertTrue(lwwDictionary.value(forKey: "key") == "value")
    }
    
    func test_valueForKey_addSomeValueAndRemove_returnsNil() {
        lwwDictionary.updateValue("value", forKey: "key")
        lwwDictionary.removeValue(forKey: "key")
        XCTAssertTrue(lwwDictionary.value(forKey: "key") == nil)
    }
    
    func test_valueForKey_addSomeValueAndRemoveAndAdd_returnsThisValue() {
        lwwDictionary.updateValue("value", forKey: "key")
        lwwDictionary.removeValue(forKey: "key")
        lwwDictionary.updateValue("value", forKey: "key")
        XCTAssertTrue(lwwDictionary.value(forKey: "key") == "value")
    }
    
    func test_updateValue_addSomeValues_valueWasAdded() {
        let pairs = predeterminedKeyValuePairs(n: 3)
        pairs.forEach {
            lwwDictionary.updateValue($0.1, forKey: $0.0)
        }
        
        pairs.forEach {
            let value = lwwDictionary.value(forKey: $0.0)
            XCTAssertEqual(value, $0.1)
        }
    }
    
    func test_updateValue_updateAdedEarlierValue_valueWasUpdated() {
        let pairs = [("2", "two"), ("1", "two"), ("2", "three")]
        pairs.forEach {
            lwwDictionary.updateValue($0.1, forKey: $0.0)
        }
        let lastPair = pairs.last!
        let addedValue = lwwDictionary.value(forKey: lastPair.0)
        XCTAssertEqual(addedValue, lastPair.1)
    }
    
    func test_removeValue_removeAnyValueFromEmptyDictionary_thereIsNoCrash() {
        lwwDictionary.removeValue(forKey: "1")
        XCTAssertTrue(true)
    }
    
    func test_remove_removeReceintlyAddedValue_removedValueIsAbsent() {
        lwwDictionary.updateValue("value", forKey: "key")
        lwwDictionary.removeValue(forKey: "key")
        let value = lwwDictionary.value(forKey: "key")
        XCTAssertNil(value)
    }
    
    func test_remove_addAndThenLaterRemoveSomeValue_valueIsAbsent() {
        lwwDictionary.updateValue("value", forKey: "key")
        lwwDictionary.removeValue(forKey: "key")
        XCTAssertNil(lwwDictionary.value(forKey: "key"))
    }
    
    func test_count_removeAndThenAddValue_valueExists() {
        lwwDictionary.removeValue(forKey: "key")
        lwwDictionary.updateValue("value", forKey: "key")
        XCTAssertNotNil(lwwDictionary.value(forKey: "key"))
    }
    
    func test_remove_addAndRemoveSomeValueConcurrently_valueIsAbsent() {
        timestampProvider.counter = 0
        lwwDictionary.updateValue("value", forKey: "key")
        timestampProvider.counter = 0
        lwwDictionary.removeValue(forKey: "key")
        XCTAssertTrue(lwwDictionary.value(forKey: "key") == nil)
    }
    
    func test_count_initialValueIsZero() throws {
        XCTAssertEqual(lwwDictionary.count, 0)
    }
    
    func test_count_addOneValue_countIsOne() {
        lwwDictionary.updateValue("value", forKey: "key")
        XCTAssertTrue(lwwDictionary.count == 1)
    }
    
    /// Later means with earlier value of timestamp in contrast with "concurrent" removal with the same timestamp.
    func test_count_addAndThenRemoveValueLater_countIsZero() {
        lwwDictionary.updateValue("value", forKey: "key")
        lwwDictionary.removeValue(forKey: "key")
        XCTAssertTrue(lwwDictionary.count == 0)
    }
    
    func test_count_removeAndThenAddValue_countIsOne() {
        lwwDictionary.removeValue(forKey: "key")
        lwwDictionary.updateValue("value", forKey: "key")
        XCTAssertTrue(lwwDictionary.count == 1)
    }
    
    func test_count_addTheSameValueTwice_counWasIncreasedByOne() {
        lwwDictionary.updateValue("value", forKey: "key1")
        lwwDictionary.updateValue("value", forKey: "key2")
        lwwDictionary.updateValue("value", forKey: "key2")
        XCTAssertTrue(lwwDictionary.count == 2)
    }
    
    func test_keys_initialValueIsEnpty() throws {
        XCTAssertTrue(lwwDictionary.keys.isEmpty)
    }
    
    func test_keys_addOneValue_keysPropertyContainsCorrespondingKey() {
        lwwDictionary.updateValue("value", forKey: "key")
        XCTAssertTrue(lwwDictionary.keys == ["key"])
    }
    
    /// Later means with earlier value of timestamp in contrast with "concurrent" removal with the same timestamp.
    func test_keys_addAndThenRemoveValueLater_keysIsEmpty() {
        lwwDictionary.updateValue("value", forKey: "key")
        lwwDictionary.removeValue(forKey: "key")
        XCTAssertTrue(lwwDictionary.keys.isEmpty)
    }
    
    func test_keys_removeAndThenAddValue_keysPropertyContainsCorrespondingKey() {
        lwwDictionary.removeValue(forKey: "key")
        lwwDictionary.updateValue("value", forKey: "key")
        XCTAssertTrue(lwwDictionary.keys == ["key"])
    }
    
    func test_remove_addAndRemoveValueConcurrently_valueIsAbsent() {
        timestampProvider.counter = 0
        lwwDictionary.updateValue("value", forKey: "key")
        timestampProvider.counter = 0
        lwwDictionary.removeValue(forKey: "key")
        XCTAssertTrue(lwwDictionary.count == 0)
    }
    
    func test_merge_mergeWithDifferentDictionary_dictinaryContainsValuesFromBothDictinaries() {
        let keyValueTimestamp1 = [("1", "one", 1), ("2", "two", 2)]
        let keyValueTimestamp2 = [("3", "three", 3), ("4", "four", 4)]
        
        let mergedLWWDict = createLWWDictionariesInAccordanceWithTimestampsAndMerge(
            keyValueTimestamp1, keyValueTimestamp2
        )
        
        let resDict = createLWWDictionaryFromInputData(keyValueTimestamp1 + keyValueTimestamp2)
        XCTAssertTrue(mergedLWWDict == resDict)
    }
    
    func test_merge_mergeWithTheSameDictionary_dictinaryContainsTheSameValues() {
        let keyValueTimestamp1 = [("1", "one", 1), ("2", "two", 2)]
        let keyValueTimestamp2 = keyValueTimestamp1
        
        let mergedLWWDict = createLWWDictionariesInAccordanceWithTimestampsAndMerge(
            keyValueTimestamp1, keyValueTimestamp2
        )
        
        let resDict = createLWWDictionaryFromInputData(keyValueTimestamp1)
        XCTAssertTrue(mergedLWWDict == resDict)
    }
    
    func test_merge_mergeWithDictionaryWithTheSameButRemovedLaterValues_dictinaryIsEmpty() {
        let keyValueTimestamp1 = [("1", "one", 1)]
        let keyValueTimestamp2 = [("1", "one", 2), ("1", nil, 3)]
        
        let mergedLWWDict = createLWWDictionariesInAccordanceWithTimestampsAndMerge(
            keyValueTimestamp1, keyValueTimestamp2
        )
        
        XCTAssertTrue(mergedLWWDict.count == 0)
    }
    
    func test_merge_mergeWithDictionaryWithTheSameButRemovedEarlierValue_dictinaryIsTheSame() {
        let keyValueTimestamp1 = [("1", "one", 2)]
        let keyValueTimestamp2 = [("1", "one", 0), ("1", nil, 1)]
        
        let mergedLWWDict = createLWWDictionariesInAccordanceWithTimestampsAndMerge(
            keyValueTimestamp1, keyValueTimestamp2
        )
        
        let resDict = createLWWDictionaryFromInputData(keyValueTimestamp1)
        XCTAssertTrue(mergedLWWDict == resDict)
    }
    
    func test_merge_mergeWithDictionaryWithTheSameButRemovedAtTheSameTimeValue_dictinaryIsTheSame() {
        let keyValueTimestamp1 = [("1", "one", 2)]
        let keyValueTimestamp2 = [("1", "one", 1), ("1", nil, 2)]
        
        let mergedLWWDict = createLWWDictionariesInAccordanceWithTimestampsAndMerge(
            keyValueTimestamp1, keyValueTimestamp2
        )
        
        let resDict = createLWWDictionaryFromInputData([])
        XCTAssertTrue(mergedLWWDict == resDict)
    }
    
    func test_merge_mergeWithDictionaryWithDifferentButRemovedLaterValues_dictinaryIsTheSame() {
        let keyValueTimestamp1 = [("1", "one", 1)]
        let keyValueTimestamp2 = [("2", "one", 2), ("2", nil, 3)]
        
        let mergedLWWDict = createLWWDictionariesInAccordanceWithTimestampsAndMerge(
            keyValueTimestamp1, keyValueTimestamp2
        )
        
        let resDict = createLWWDictionaryFromInputData(keyValueTimestamp1)
        XCTAssertTrue(mergedLWWDict == resDict)
    }
    
    func test_merge_mergeWithDictionaryWithTheSameButSomeRemovedValues_dictinaryIsTheSame() {
        let keyValueTimestamp1 = [("1", "one", 1), ("2", "two", 2)]
        let keyValueTimestamp2 = [("1", "one", 2), ("2", "two", 3), ("2", nil, 4)]
        
        let mergedLWWDict = createLWWDictionariesInAccordanceWithTimestampsAndMerge(
            keyValueTimestamp1, keyValueTimestamp2
        )
        
        let resDict = createLWWDictionaryFromInputData([("1", "one", 2)])
        XCTAssertTrue(mergedLWWDict == resDict)
    }
    
    func test_merge_mergeWithDictionaryWithConflictingValuesWithDifferentTimestamps_correctlyMergedDict() {
        let keyValueTimestamp1 = [("1", "one1", 1), ("2", "two1", 2)]
        let keyValueTimestamp2 = [("1", "one2", 0), ("2", "two2", 3)]
        
        let mergedLWWDict = createLWWDictionariesInAccordanceWithTimestampsAndMerge(
            keyValueTimestamp1, keyValueTimestamp2
        )
        
        let resDict = createLWWDictionaryFromInputData([("1", "one1", 1), ("2", "two2", 3)])
        XCTAssertTrue(mergedLWWDict == resDict)
    }
    
    func test_merge_mergeWithDictionaryWithConflictingValueWithSameTimestamp_conflictResolvesToValueInBeingMergeIntoDict() {
        let keyValueTimestamp1 = [("1", "one1", 1)]
        let keyValueTimestamp2 = [("1", "one2", 1)]
        
        let mergedLWWDict = createLWWDictionariesInAccordanceWithTimestampsAndMerge(
            keyValueTimestamp1, keyValueTimestamp2
        )
        
        let resDict = createLWWDictionaryFromInputData([("1", "one1", 1)])
        XCTAssertTrue(mergedLWWDict == resDict)
    }
    
    func test_merge_mergeDictionariesWithRemovedValues_correctlyMergedDict() {
        let keyValueTimestamp1 = [("1", "one1", 1), ("1", nil, 1), ("2", "two1", 3)]
        let keyValueTimestamp2 = [("1", "one2", 0), ("1", nil, 2), ("2", "two2", 4)]
        
        let mergedLWWDict = createLWWDictionariesInAccordanceWithTimestampsAndMerge(
            keyValueTimestamp1, keyValueTimestamp2
        )
        
        let resDict = createLWWDictionaryFromInputData([("2", "two1", 3), ("2", "two2", 4)])
        XCTAssertTrue(mergedLWWDict == resDict)
    }
    
    func test_merge_mergeEmptyLWWDictionaryWithOtherLWWDictionary_resultIsEqualToOtherDictionary() {
        let keyValueTimestamp1 = [(String, String, Int)]()
        let keyValueTimestamp2 = [("1", "one2", 0), ("2", "two2", 2), ("3", "three2", 3)]
        
        let mergedLWWDict = createLWWDictionariesInAccordanceWithTimestampsAndMerge(
            keyValueTimestamp1, keyValueTimestamp2
        )
        
        let resDict = createLWWDictionaryFromInputData([("1", "one2", 0), ("2", "two2", 2), ("3", "three2", 3)])
        XCTAssertTrue(mergedLWWDict == resDict)
    }
    
    func test_merge_mergeLWWDictionaryWithEmptyLWWDictionary_initialDictionaryHasNotChanged() {
        let keyValueTimestamp1 = [("1", "one1", 1), ("2", "two1", 2), ("3", "three1", 2)]
        let keyValueTimestamp2 = [(String, String, Int)]()
        
        let mergedLWWDict = createLWWDictionariesInAccordanceWithTimestampsAndMerge(
            keyValueTimestamp1, keyValueTimestamp2
        )
        
        let resDict = createLWWDictionaryFromInputData([("1", "one1", 1), ("2", "two1", 2), ("3", "three1", 2)])
        XCTAssertTrue(mergedLWWDict == resDict)
    }
    
    func test_equal_compareToEmptyDictionaries_comparissonPassed() {
        let keyValueTimestamp1 = [(String, String, Int)]()
        let keyValueTimestamp2 = [(String, String, Int)]()
        
        let resDict1 = createLWWDictionaryFromInputData(keyValueTimestamp1)
        let resDict2 = createLWWDictionaryFromInputData(keyValueTimestamp2)
        XCTAssertTrue(resDict1 == resDict2)
    }
    
    func test_equal_compareToSomeDictionaryWithEmptyOne_comparissonFailed() {
        let keyValueTimestamp1 = [(String, String, Int)]()
        let keyValueTimestamp2 = [(String, String, Int)]()
        
        let resDict1 = createLWWDictionaryFromInputData(keyValueTimestamp1)
        let resDict2 = createLWWDictionaryFromInputData(keyValueTimestamp2)
        XCTAssertTrue(resDict1 == resDict2)
    }
    
    func test_equal_compareToUnequalDictionaries_comparissonFailed() {
        let keyValueTimestamp1 = [("1", "one1", 1), ("1", nil, 2), ("2", "two1", 3)]
        let keyValueTimestamp2 = [("1", "one2", 0), ("1", nil, 3), ("2", "two2", 4)]
        
        let resDict1 = createLWWDictionaryFromInputData(keyValueTimestamp1)
        let resDict2 = createLWWDictionaryFromInputData(keyValueTimestamp2)
        XCTAssertTrue(resDict1 != resDict2)
    }

    func test_equal_compareToEquivalentDictionaries_comparissonPassed() {
        let keyValueTimestamp1 = [("1", "one1", 1), ("1", nil, 2), ("2", "two", 3)]
        let keyValueTimestamp2 = [("1", "one2", 0), ("1", nil, 3), ("2", "two", 4)]
        
        let resDict1 = createLWWDictionaryFromInputData(keyValueTimestamp1)
        let resDict2 = createLWWDictionaryFromInputData(keyValueTimestamp2)
        XCTAssertTrue(resDict1 == resDict2)
    }
    
    /// `nil` in value of input triple corresponds to remove operation
    private func createLWWDictionariesInAccordanceWithTimestampsAndMerge(
        _ keyValueTimestamp1: [(String, String?, Int)],
        _ keyValueTimestamp2: [(String, String?, Int)]) -> LWWElementDictionary<String, TimestampProviderMock> {
        
        var lwwDictionary1 = createLWWDictionaryFromInputData(keyValueTimestamp1)
        let lwwDictionary2 = createLWWDictionaryFromInputData(keyValueTimestamp2)

        lwwDictionary1.merge(lwwDictionary2)
        return lwwDictionary1
    }
    
    /// `nil` in value of input triple corresponds to remove operation
    private func createLWWDictionaryFromInputData(
        _ keyValueTimestamp: [(String, String?, Int)]) -> LWWElementDictionary<String, TimestampProviderMock> {
        
        let timestampProvider = TimestampProviderMock()
        var lwwDictionary = LWWElementDictionary<String, TimestampProviderMock>(
            timestampProvider: timestampProvider
        )
        
        keyValueTimestamp.forEach {
            timestampProvider.counter = $0.2
            if let value = $0.1 {
                lwwDictionary.updateValue(value, forKey: $0.0)
            }
            else {
                lwwDictionary.removeValue(forKey: $0.0)
            }
        }
        return lwwDictionary
    }
    
    /// `nil` in value of input triple corresponds to remove operation
    private func mergeInputDataInAccordanceWithLWWDictionaryRulesAndTransfromIntoLWWDictionary(
        _ keyValueTimestamp1: [(String, String?, Int)],
        _ keyValueTimestamp2: [(String, String?, Int)]) -> [String : String] {
        
        let keyPairedValueWithTimestamp1 = keyValueTimestamp1.map { ($0.0, ($0.1, $0.2) ) }
        let keyPairedValueWithTimestamp2 = keyValueTimestamp2.map { ($0.0, ($0.1, $0.2) ) }

        var keyToValueWithTimestamp1 = Dictionary(keyPairedValueWithTimestamp1) {
            (vt1, vt2) in vt2.1 > vt1.1 ? vt2 : vt1
        }
        let keyToValueWithTimestamp2 = Dictionary(keyPairedValueWithTimestamp2) {
            (vt1, vt2) in vt2.1 > vt1.1 ? vt2 : vt1
        }
        
        keyToValueWithTimestamp1.merge(keyToValueWithTimestamp2) {
            (current, new) in new.1 > current.1 ? new : current
        }
        
        return keyToValueWithTimestamp1.compactMapValues { (optionalValue, timestamp) in optionalValue }
    }
}

fileprivate extension LWWElementDictionary where Value: Equatable {
    func isEquivalentTo(dictionary: [String : Value]) -> Bool {
        guard self.count == dictionary.count else { return false }
        for key in dictionary.keys {
            if value(forKey: key) != dictionary[key] {
                return false
            }
        }
        return true
    }
}
