import Foundation

public enum ProviderError: Error, Equatable, Sendable {
    case serviceUnavailable(service: String)
    case modelNotFound(service: String, model: String)
    case apiKeyMissing(service: String)
    case authenticationFailed(service: String)
    case networkUnavailable
    case timedOut
    case invalidResponse(service: String)
    case requestFailed(service: String, statusCode: Int)
    case unexpected(service: String)

    static func map(_ error: Error, service: String) -> ProviderError {
        if let providerError = error as? ProviderError {
            return providerError
        }
        if error is DecodingError {
            return .invalidResponse(service: service)
        }
        guard let urlError = error as? URLError else {
            return .unexpected(service: service)
        }

        switch urlError.code {
        case .timedOut:
            return .timedOut
        case .cannotConnectToHost, .cannotFindHost, .networkConnectionLost:
            return .serviceUnavailable(service: service)
        default:
            return .networkUnavailable
        }
    }
}

extension ProviderError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .serviceUnavailable(service):
            "\(service) is unavailable. Check that the service is running."
        case let .modelNotFound(service, model):
            "\(service) could not find the model “\(model)”. Check your model settings."
        case let .apiKeyMissing(service):
            "\(service) API key is missing. Add it in Settings."
        case let .authenticationFailed(service):
            "\(service) authentication failed. Check your API key."
        case .networkUnavailable:
            "The network is unavailable. Check your connection."
        case .timedOut:
            "The request timed out. Please try again."
        case let .invalidResponse(service):
            "\(service) returned an invalid response."
        case let .requestFailed(service, statusCode):
            "\(service) request failed with status \(statusCode)."
        case let .unexpected(service):
            "An unexpected \(service) error occurred."
        }
    }
}
