import Foundation
import CoreGraphics

/// Assessment module for Shoulder Range of Motion (Flexion or Abduction).
class ShoulderROMAssessment: AssessmentModule {
    let id: String
    let title: String
    let instructions: [String]
    
    private var maxLeftAngle: Double = 0
    private var maxRightAngle: Double = 0
    private var leftConfidence: Float = 0
    private var rightConfidence: Float = 0
    private var frameCount: Int = 0
    
    init(type: ROMType) {
        self.id = "shoulder_\(type.rawValue)"
        self.title = type == .flexion ? "Omuz Fleksiyonu" : "Omuz Abduksiyonu"
        self.instructions = [
            "Kollarınızı \(type == .flexion ? "önden" : "yanlardan") yukarı kaldırın.",
            "Mümkün olduğunca yukarı uzanın.",
            "Yavaşça başlangıç pozisyonuna dönün."
        ]
    }
    
    enum ROMType: String {
        case flexion
        case abduction
    }
    
    func processPose(_ pose: BodyPose) {
        guard let leftShoulder = pose.joint(.leftShoulder),
              let leftWrist = pose.joint(.leftWrist),
              let rightShoulder = pose.joint(.rightShoulder),
              let rightWrist = pose.joint(.rightWrist) else { return }
        
        // Calculate angle relative to vertical downward (0 degrees is arm at side)
        // For flexion/abduction, we can use the angle between (Shoulder-Hip) and (Shoulder-Wrist)
        // or simpler: angle relative to the vertical axis.
        
        let leftAngle = calculateArmAngle(shoulder: leftShoulder.position, wrist: leftWrist.position)
        let rightAngle = calculateArmAngle(shoulder: rightShoulder.position, wrist: rightWrist.position)
        
        if leftAngle > maxLeftAngle { 
            maxLeftAngle = leftAngle
            leftConfidence = leftShoulder.confidence * leftWrist.confidence
        }
        
        if rightAngle > maxRightAngle { 
            maxRightAngle = rightAngle
            rightConfidence = rightShoulder.confidence * rightWrist.confidence
        }
        
        frameCount += 1
    }
    
    private func calculateArmAngle(shoulder: CGPoint, wrist: CGPoint) -> Double {
        // In iOS Vision coordinates, Y=0 is TOP of screen, Y=1 is BOTTOM.
        // "Upward" is shoulder.y - 0.5 (i.e., a point above the shoulder).
        // angle(a: above, b: shoulder, c: wrist) gives angle at shoulder vertex
        // between upward vertical and the arm vector.
        // 0° = arm straight up, 90° = arm horizontal, 180° = arm straight down (rest)
        let above = CGPoint(x: shoulder.x, y: shoulder.y - 0.5) // point directly above shoulder
        let raw = GeometryEngine.angle(a: above, b: shoulder, c: wrist)
        // Clamp to 0–180 — Vision can produce noisy landmarks
        return max(0, min(180, raw))
    }
    
    func finish() -> AssessmentTestResult {
        let measurements: [String: MeasurementResult] = [
            "leftShoulderROM": MeasurementResult(
                value: maxLeftAngle,
                unit: "°",
                confidence: Double(leftConfidence),
                quality: leftConfidence > 0.6 ? .high : .acceptable
            ),
            "rightShoulderROM": MeasurementResult(
                value: maxRightAngle,
                unit: "°",
                confidence: Double(rightConfidence),
                quality: rightConfidence > 0.6 ? .high : .acceptable
            ),
            "difference": MeasurementResult(
                value: abs(maxLeftAngle - maxRightAngle),
                unit: "°",
                confidence: Double(min(leftConfidence, rightConfidence)),
                quality: .acceptable
            )
        ]
        
        return AssessmentTestResult(
            id: UUID(),
            type: id,
            measurements: measurements,
            overallQuality: frameCount > 30 ? .high : .low
        )
    }
    
    func reset() {
        maxLeftAngle = 0
        maxRightAngle = 0
        frameCount = 0
    }
}
