//
//  ClipboardControllerTests.swift
//  ClipboardMonitorTests
//

import Foundation
import UniformTypeIdentifiers
import XCTest
@testable import ClipboardMonitor

@MainActor
final class ClipboardControllerTests: XCTestCase {

    private var repository: InMemorySnapshotRepository!
    private var reader: FakePasteboardReader!
    private var controller: ClipboardController!

    override func setUp() {
        super.setUp()
        repository = InMemorySnapshotRepository()
        reader = FakePasteboardReader()
        controller = ClipboardController(repository: repository, reader: reader)
    }

    func testCaptureSnapshotAddsNonEmptyPasteboard() {
        reader.changeCount = 1
        reader.snapshotToReturn = PasteboardSnapshot(items: [
            TestFixtures.item(TestFixtures.representation(type: .plainText, string: "hello"))
        ])

        controller.captureSnapshot()

        XCTAssertEqual(repository.snapshots.count, 1)
        XCTAssertEqual(repository.snapshots.first?.representations.first?.rawType, UTType.plainText.identifier)
    }

    func testCaptureSnapshotSkipsEmptyPasteboard() {
        reader.changeCount = 1
        reader.snapshotToReturn = PasteboardSnapshot(items: [])

        controller.captureSnapshot()

        XCTAssertTrue(repository.snapshots.isEmpty)
    }

    func testCaptureSnapshotSkipsUnchangedChangeCount() {
        reader.changeCount = 7
        reader.snapshotToReturn = PasteboardSnapshot(items: [
            TestFixtures.item(TestFixtures.representation(type: .plainText, string: "same"))
        ])

        controller.captureSnapshot()
        reader.snapshotToReturn = PasteboardSnapshot(items: [
            TestFixtures.item(TestFixtures.representation(type: .plainText, string: "different"))
        ])
        controller.captureSnapshot()

        XCTAssertEqual(repository.snapshots.count, 1)
        XCTAssertEqual(
            String(data: repository.snapshots[0].representations[0].data, encoding: .utf8),
            "same"
        )
    }

    func testSkipsFlattenedDuplicate() {
        let text = TestFixtures.representation(type: .plainText, string: "hello")
        let html = TestFixtures.representation(type: .html, string: "<p>hello</p>")

        repository.add(PasteboardSnapshot(items: [
            RawPasteboardItem(representations: [
                html,
                RawRepresentation(rawType: text.rawType, type: nil, data: text.data),
            ])
        ]))

        reader.changeCount = 1
        reader.snapshotToReturn = PasteboardSnapshot(items: [
            TestFixtures.item(text),
            TestFixtures.item(html),
        ])
        controller.captureSnapshot()

        XCTAssertEqual(repository.snapshots.count, 1)
    }

    func testCaptureSnapshotAddsWhenContentChanges() {
        reader.changeCount = 1
        reader.snapshotToReturn = PasteboardSnapshot(items: [
            TestFixtures.item(TestFixtures.representation(type: .plainText, string: "one"))
        ])
        controller.captureSnapshot()

        reader.changeCount = 2
        reader.snapshotToReturn = PasteboardSnapshot(items: [
            TestFixtures.item(TestFixtures.representation(type: .plainText, string: "two"))
        ])
        controller.captureSnapshot()

        XCTAssertEqual(repository.snapshots.count, 2)
    }
}

@MainActor
final class PasteboardSnapshotContentTests: XCTestCase {

    func testHasSameClipboardContentIgnoresItemBoundariesAndOrder() {
        let a = TestFixtures.representation(type: .plainText, string: "a")
        let b = TestFixtures.representation(type: .utf8PlainText, string: "b")

        let multiItem = PasteboardSnapshot(items: [
            TestFixtures.item(a),
            TestFixtures.item(b),
        ])
        let flattenedReversed = PasteboardSnapshot(items: [
            RawPasteboardItem(representations: [b, a])
        ])

        XCTAssertTrue(multiItem.hasSameClipboardContent(as: flattenedReversed))
    }

    func testHasSameClipboardContentIgnoresResolvedUTType() {
        let data = Data("hello".utf8)
        let withType = PasteboardSnapshot(items: [
            TestFixtures.item(RawRepresentation(rawType: "public.utf8-plain-text", type: .utf8PlainText, data: data))
        ])
        let withoutType = PasteboardSnapshot(items: [
            TestFixtures.item(RawRepresentation(rawType: "public.utf8-plain-text", type: nil, data: data))
        ])

        XCTAssertTrue(withType.hasSameClipboardContent(as: withoutType))
        XCTAssertFalse(withType.items == withoutType.items)
    }
}
