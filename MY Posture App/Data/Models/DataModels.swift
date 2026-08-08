import Foundation
import SwiftData

@Model
final class PatientEntity {
    @Attribute(.unique) var id: UUID
    var firstName: String
    var lastName: String
    var birthYear: Int
    var createdAt: Date
    
    var fullName: String { "\(firstName) \(lastName)" }
    
    @Relationship(deleteRule: .cascade, inverse: \SessionEntity.patient)
    var sessions: [SessionEntity] = []
    
    init(id: UUID = UUID(), firstName: String, lastName: String, birthYear: Int = 1990) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.birthYear = birthYear
        self.createdAt = Date()
    }
}

@Model
final class SessionEntity {
    @Attribute(.unique) var id: UUID
    var date: Date
    var status: String
    
    var patient: PatientEntity?
    
    @Relationship(deleteRule: .cascade)
    var results: [TestResultEntity] = []
    
    init(id: UUID = UUID(), date: Date = Date(), status: String = "completed") {
        self.id = id
        self.date = date
        self.status = status
    }
}

@Model
final class TestResultEntity {
    @Attribute(.unique) var id: UUID
    var testType: String
    var quality: String
    var confidence: Double
    
    @Relationship(deleteRule: .cascade)
    var measurements: [MeasurementEntity] = []
    
    init(id: UUID = UUID(), testType: String, quality: String, confidence: Double) {
        self.id = id
        self.testType = testType
        self.quality = quality
        self.confidence = confidence
    }
}

@Model
final class MeasurementEntity {
    @Attribute(.unique) var id: UUID
    var key: String
    var value: Double
    var unit: String
    var confidence: Double
    
    init(id: UUID = UUID(), key: String, value: Double, unit: String, confidence: Double) {
        self.id = id
        self.key = key
        self.value = value
        self.unit = unit
        self.confidence = confidence
    }
}
