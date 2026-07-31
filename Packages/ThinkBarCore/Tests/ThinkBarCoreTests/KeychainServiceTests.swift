import Foundation
import Testing
@testable import ThinkBarCore

struct KeychainServiceTests {
    @Test func savesLoadsUpdatesAndDeletesSecret() throws {
        let identifier = UUID().uuidString
        let storage = KeychainService(service: "com.sliceapp.thinkbar.tests.\(identifier)")
        let key = "openRouter.apiKey"
        defer { try? storage.delete(key: key) }

        #expect(try storage.load(key: key) == nil)

        try storage.save(key: key, value: "first-key")
        #expect(try storage.load(key: key) == "first-key")

        try storage.save(key: key, value: "updated-key")
        #expect(try storage.load(key: key) == "updated-key")

        try storage.delete(key: key)
        #expect(try storage.load(key: key) == nil)
    }
}
