//
//  TypedMap.swift
//  Swift47Deg
//
//  Created by Javier de Silóniz Sandino on 9/3/15.
//  Copyright (c) 2015 47 Degrees. All rights reserved.
//

import Foundation

/// Map | An immutable iterable collection containing pairs of keys and values. Each key is of type HashableAny to allow to have keys with different types (currently supported types are Int, Float, and String). Each value is of a type T. If you need to store values of different types, use the type Map.
struct TypedMap<T> {
    private var internalDict : Dictionary<Key, Value>
    
    subscript(key: Key) -> Value? {
        get {
            return internalDict[key]
        }
        set {
            internalDict[key] = newValue
        }
    }
    
    var count : Int {
        return self.internalDict.count
    }
}

extension TypedMap : DictionaryLiteralConvertible {
    typealias Key = HashableAny
    typealias Value = T
    
    init(dictionaryLiteral elements: (Key, Value)...) {
        var tempDict = Dictionary<Key, Value>()
        for element in elements {
            tempDict[element.0] = element.1
        }
        internalDict = tempDict
    }
}

extension TypedMap : SequenceType {
    typealias Generator = GeneratorOf<(Key, Value)>
    
    func generate() -> Generator {
        var index : Int = 0
        
        return Generator {
            if index < self.internalDict.count {
                let key = Array(self.internalDict.keys)[index]
                index++
                return (key, self.internalDict[key]!)
            }
            return nil
        }
    }
}

// MARK: Higher-order functions
extension TypedMap {
    init(_ arrayOfGenerators: [Generator.Element]) {
        self = TypedMap() + arrayOfGenerators
    }
    
    /**
    Returns a new typed map containing all the keys from the current map that satisfy the `includeElement` closure. Only takes into account values, not keys.
    */
    func filter(includeElement: (Value) -> Bool) -> TypedMap {
        return TypedMap(Swift.filter(self, { (key: Key, value: Value) -> Bool in
            includeElement(value)
        }))
    }
    
    /**
    Returns a new typed map containing all the keys/value pairs from the current one that satisfy the `includeElement` closure. Takes into account both values AND keys.
    */
    func filter(includeElement: ((Key, Value)) -> Bool) -> TypedMap {
        return TypedMap(Swift.filter(self, { (key: Key, value: Value) -> Bool in
            includeElement((key, value))
        }))
    }
    
    /**
    Returns a new map containing all the keys from the current one that satisfy the `includeElement` closure.
    */
    func filterKeys(includeElement: (Key) -> Bool) -> TypedMap {
        return self.filter({ (item: (key: Key, value: Value)) -> Bool in
            includeElement(item.key)
        })
    }
    
    /**
    Returns a new typed map obtained by removing all key/value pairs for which the `removeElement` closure returns true.
    */
    func filterNot(removeElement: ((Key, Value)) -> Bool) -> TypedMap {
        let itemsToExclude = self.filter(removeElement)
        return self -- itemsToExclude.keys
    }
    
    /**
    Returns a new typed map containing the results of mapping `transform` over its elements.
    */
    func map(transform: (Value) -> Value) -> TypedMap {
        return TypedMap(Swift.map(self, { (key: Key, value: Value) -> (Key, Value) in
            return (key, transform(value))
        }))
    }
    
    /**
    Returns the result of repeatedly calling combine with an accumulated value initialized to `initial` and each element of the current typed map.
    */
    func reduce<U>(initialValue: U, combine: (U, Value) -> U) -> U {
        return Swift.reduce(self, initialValue) { (currentTotal, currentElement) -> U in
            return combine(currentTotal, currentElement.1)
        }
    }
    
    /**
    Returns the first element of the typed map satisfying a predicate, if any. Note: might return different results for different runs, as the underlying collection type is unordered.
    
    :param: predicate The predicate to check the map items against
    */
    func find(predicate: ((Key, Value) -> Bool)) -> (Key, Value)? {
        return Swift.filter(self, predicate)[0]
    }
}

// MARK: Basic utils
extension TypedMap {
    /**
    :returns: An array containing all the keys from the current typed map. Note: might return different results for different runs, as the underlying collection type is unordered.
    */
    var keys : [Key] {
        return Array(internalDict.keys)
    }
    
    /**
    :returns: True if the typed map doesn't contain any element.
    */
    func isEmpty() -> Bool {
        return internalDict.keys.isEmpty
    }
    
    /**
    :returns: An array containing the different values from the current typed map. Note: might return different results for different runs, as the underlying collection type is unordered.
    */
    func values() -> [Value] {
        return Array(internalDict.values)
    }
    
    /**
    Checks if a certain key is binded to a value in the current typed map.
    
    :param: key The key to be checked.
    
    :returns: True if the typed map contains an element binded to the key.
    */
    func contains(key: Key) -> Bool {
        return internalDict[key] != nil
    }
    
    /**
    Selects all elements except the first n ones. Note: might return different results for different runs, as the underlying collection type is unordered.
    
    :param: n Number of elements to be excluded from the selection
    
    :returns: A new typed map containing the elements from the selection
    */
    func drop(n: Int) -> TypedMap {
        let keys = self.keys
        let keysToExclude = keys.filter({ Swift.find(keys, $0) < n })
        return self -- keysToExclude
    }
    
    /**
    Selects all elements except the last n ones. Note: might return different results for different runs, as the underlying collection type is unordered.
    
    :param: n Number of elements to be excluded from the selection
    
    :returns: A new typed map containing the elements from the selection
    */
    func dropRight(n: Int) -> TypedMap {
        let keys = self.keys
        let keysToExclude = keys.filter({ Swift.find(keys, $0) >= self.count - n })
        return self -- keysToExclude
    }
    
    /**
    Drops longest prefix of elements that satisfy a predicate. Note: might return different results for different runs, as the underlying collection type is unordered.
    
    :param: n Number of elements to be excluded from the selection
    
    :returns: The longest suffix of this traversable collection whose first element does not satisfy the predicate p.
    */
    func dropWhile(p: (Key, Value) -> Bool) -> TypedMap {
        func findSuffixFirstIndex() -> Int? {
            var count = 0
            for key in self.keys {
                if let value = self[key] {
                    if !p(key, value) {
                        return count
                    }
                }
                count++
            }
            return nil
        }
        
        if let firstIndex = findSuffixFirstIndex() {
            return self.drop(firstIndex)
        }
        return self
    }
    
    /**
    Tests whether a predicate holds for some of the elements of this map.
    
    :param: p Predicate to check against the elements of this map
    */
    func exists(p: ((Key, Value)) -> Bool) -> Bool {
        return self.filter(p).count > 0
    }
    
    /**
    :returns: Returns the first element of this typed map (if there are any). Note: might return different results for different runs, as the underlying collection type is unordered.
    */
    func head() -> (Key, Value)? {
        if let headKey = self.internalDict.keys.first {
            return (headKey, self[headKey]!)
        }
        return nil
    }
}