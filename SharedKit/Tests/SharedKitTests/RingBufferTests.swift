import XCTest
@testable import SharedKit

final class RingBufferTests: XCTestCase {
    func testAppendUnderCapacity() {
        let rb = RingBuffer<Int>(capacity: 4)
        rb.append(1); rb.append(2); rb.append(3)
        XCTAssertEqual(rb.snapshot(), [1, 2, 3])
    }

    func testOverflowDropsOldest() {
        let rb = RingBuffer<Int>(capacity: 3)
        rb.append(1); rb.append(2); rb.append(3); rb.append(4); rb.append(5)
        XCTAssertEqual(rb.snapshot(), [3, 4, 5])
    }

    func testClear() {
        let rb = RingBuffer<Int>(capacity: 3)
        rb.append(1); rb.append(2)
        rb.clear()
        XCTAssertEqual(rb.snapshot(), [])
    }
}
