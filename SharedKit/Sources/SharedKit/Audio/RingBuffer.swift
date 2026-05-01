import Foundation

public final class RingBuffer<Element>: @unchecked Sendable {
    private var storage: [Element?]
    private var head = 0
    private var tail = 0
    private var count = 0
    public let capacity: Int
    private let lock = NSLock()

    public init(capacity: Int) {
        self.capacity = capacity
        self.storage = Array(repeating: nil, count: capacity)
    }

    public func append(_ element: Element) {
        lock.lock(); defer { lock.unlock() }
        storage[tail] = element
        tail = (tail + 1) % capacity
        if count < capacity {
            count += 1
        } else {
            head = (head + 1) % capacity
        }
    }

    public func snapshot() -> [Element] {
        lock.lock(); defer { lock.unlock() }
        var out: [Element] = []
        out.reserveCapacity(count)
        for i in 0..<count {
            if let v = storage[(head + i) % capacity] {
                out.append(v)
            }
        }
        return out
    }

    public func clear() {
        lock.lock(); defer { lock.unlock() }
        storage = Array(repeating: nil, count: capacity)
        head = 0; tail = 0; count = 0
    }
}
