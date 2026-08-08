import Foundation

/// Represents the quality of a clinical measurement.
enum MeasurementQuality: String, Codable {
    case high
    case acceptable
    case low
    case invalid
}

/// Represents a clinical measurement with confidence and quality metadata.
struct MeasurementResult: Identifiable, Codable {
    let id: UUID
    let value: Double
    let unit: String
    let confidence: Double
    let quality: MeasurementQuality
    let timestamp: Date
    
    init(id: UUID = UUID(), value: Double, unit: String, confidence: Double, quality: MeasurementQuality, timestamp: Date = Date()) {
        self.id = id
        self.value = value
        self.unit = unit
        self.confidence = confidence
        self.quality = quality
        self.timestamp = timestamp
    }
}

/// A collection of measurements for a specific test.
struct AssessmentTestResult: Identifiable, Codable {
    let id: UUID
    let type: String // e.g., "FrontPosture"
    let measurements: [String: MeasurementResult]
    let overallQuality: MeasurementQuality
    
    var isSuccessful: Bool {
        overallQuality == .high || overallQuality == .acceptable
    }
}
