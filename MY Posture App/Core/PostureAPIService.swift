import Foundation
import Combine
import UIKit

// MARK: - Models

struct PostureLookupResponse: Codable {
    let userId: String
    let userName: String
    let appointmentCode: String
    let patientProfile: PatientProfileInfo?
}

struct PatientProfileInfo: Codable {
    let age: Int?
    let gender: String?
    let phone: String?
}

struct ClinicianPatientResponse: Codable {
    let id: String
    let name: String
    let birthYear: Int
    let lastSessionDate: String?
}

struct PaginatedPatientsResponse: Codable {
    let items: [ClinicianPatientResponse]
    let page: Int
    let totalPages: Int
}

struct PostureSessionPayload: Codable {
    let userId: String
    let appointmentCode: String?
    let deviceInfo: String?
    let testResults: [TestResultPayload]
}

struct TestResultPayload: Codable {
    let testType: String
    let overallQuality: String
    let avgConfidence: Double
    let measurements: [MeasurementPayload]
}

struct MeasurementPayload: Codable {
    let metricKey: String
    let value: Double
    let unit: String
    let confidence: Double
    let quality: String
}

struct PostureSessionResponse: Codable {
    let sessionId: String
    let createdAt: String
}

// MARK: - API Service

/// Handles all communication between the iOS Posture App and the MY FizyoAI backend.
class PostureAPIService: ObservableObject {
    static let shared = PostureAPIService()

    /// ⚠️  Production URL'ini buraya girin. Geliştirme sırasında local IP kullanılabilir.
    #if DEBUG
    private let baseURL = "https://my.cerilas.com"   // veya local: "http://192.168.x.x:3000"
    #else
    private let baseURL = "https://my.cerilas.com"
    #endif

    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // MARK: - Lookup Appointment Code

    /// Randevu kodunu doğrular ve eşleşen userId'yi döner.
    func lookupCode(_ code: String) async throws -> PostureLookupResponse {
        let url = URL(string: "\(baseURL)/api/posture/lookup-code")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["code": code.uppercased()])
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try decoder.decode(PostureLookupResponse.self, from: data)
    }

    // MARK: - Save Session

    /// Tamamlanan posture oturumunu kaydeder.
    func saveSession(
        userId: String,
        appointmentCode: String?,
        testResults: [AssessmentTestResult]
    ) async throws -> PostureSessionResponse {
        let payload = PostureSessionPayload(
            userId: userId,
            appointmentCode: appointmentCode,
            deviceInfo: deviceInfo(),
            testResults: testResults.map { result in
                TestResultPayload(
                    testType: result.type,
                    overallQuality: result.overallQuality.rawValue,
                    avgConfidence: result.measurements.values
                        .map(\.confidence)
                        .reduce(0, +) / Double(max(1, result.measurements.count)),
                    measurements: result.measurements.map { key, m in
                        MeasurementPayload(
                            metricKey: key,
                            value: m.value,
                            unit: m.unit,
                            confidence: m.confidence,
                            quality: m.quality.rawValue
                        )
                    }
                )
            }
        )

        let url = URL(string: "\(baseURL)/api/posture/sessions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)
        request.timeoutInterval = 30

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try decoder.decode(PostureSessionResponse.self, from: data)
    }
    
    // MARK: - Fetch Patients (Admin Panel)
    
    /// Gerçek veritabanından hasta listesini çeker (sayfalama destekli).
    func fetchPatients(pin: String, page: Int = 1, search: String = "") async throws -> PaginatedPatientsResponse {
        var components = URLComponents(string: "\(baseURL)/api/posture/patients")!
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "20")
        ]
        
        if !search.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "search", value: search))
        }
        
        guard let url = components.url else {
            throw PostureAPIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(pin, forHTTPHeaderField: "x-admin-pin")
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try decoder.decode(PaginatedPatientsResponse.self, from: data)
    }

    // MARK: - Helpers

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw PostureAPIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
                ?? "HTTP \(http.statusCode)"
            throw PostureAPIError.serverError(message)
        }
    }

    private func deviceInfo() -> String {
        let device = UIDevice.current
        return "\(device.model) / iOS \(device.systemVersion)"
    }
}

// MARK: - Errors

enum PostureAPIError: LocalizedError {
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Sunucudan geçersiz yanıt alındı."
        case .serverError(let msg): return msg
        }
    }
}
