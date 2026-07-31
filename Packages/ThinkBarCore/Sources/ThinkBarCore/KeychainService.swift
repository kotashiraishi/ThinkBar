import Foundation
import Security

public protocol SecretStorage: Sendable {
    func save(key: String, value: String) throws
    func load(key: String) throws -> String?
    func delete(key: String) throws
}

public struct KeychainService: SecretStorage {
    private let service: String

    public init(service: String = "com.sliceapp.thinkbar") {
        self.service = service
    }

    public func save(key: String, value: String) throws {
        let data = Data(value.utf8)
        let query = query(for: key)
        let update = [kSecValueData: data] as CFDictionary
        let updateStatus = SecItemUpdate(query as CFDictionary, update)

        if updateStatus == errSecSuccess {
            return
        }
        guard updateStatus == errSecItemNotFound else {
            throw KeychainServiceError.unexpectedStatus(updateStatus)
        }

        var item = query
        item[kSecValueData] = data
        let addStatus = SecItemAdd(item as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainServiceError.unexpectedStatus(addStatus)
        }
    }

    public func load(key: String) throws -> String? {
        var query = query(for: key)
        query[kSecMatchLimit] = kSecMatchLimitOne
        query[kSecReturnData] = true

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw KeychainServiceError.unexpectedStatus(status)
        }
        guard
            let data = result as? Data,
            let value = String(data: data, encoding: .utf8)
        else {
            throw KeychainServiceError.invalidData
        }
        return value
    }

    public func delete(key: String) throws {
        let status = SecItemDelete(query(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainServiceError.unexpectedStatus(status)
        }
    }

    private func query(for key: String) -> [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
        ]
    }
}

public enum KeychainServiceError: Error, Equatable, Sendable {
    case unexpectedStatus(OSStatus)
    case invalidData
}
