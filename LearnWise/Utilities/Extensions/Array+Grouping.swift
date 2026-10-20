import Foundation

/// One group from `Array.grouped(by:)`, ready for `ForEach`.
struct ItemGroup<Key: Hashable, Element>: Identifiable {
    let key: Key
    let items: [Element]
    var id: Key { key }
}

extension Array {
    /// Groups elements by key, keeping groups in the order each key first appears.
    /// Unlike `Dictionary(grouping:)`, the result is stable, which suits List sections.
    func grouped<Key: Hashable>(by key: (Element) -> Key) -> [ItemGroup<Key, Element>] {
        var order: [Key] = []
        var groups: [Key: [Element]] = [:]
        for element in self {
            let k = key(element)
            if groups[k] == nil {
                order.append(k)
            }
            groups[k, default: []].append(element)
        }
        return order.map { ItemGroup(key: $0, items: groups[$0] ?? []) }
    }
}
