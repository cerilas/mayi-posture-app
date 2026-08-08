import Foundation
import CoreGraphics

/// Implementation of the Front Static Posture Assessment.
class FrontPostureAssessment: AssessmentModule {
    let id = "front_static_posture"
    let title = "Ön Postür Analizi"
    let instructions = [
        "Ayaklarınızı işaretlere yerleştirin.",
        "Kollarınızı serbest bırakın.",
        "Karşıya bakın.",
        "Hareket etmeyin."
    ]
    
    private var capturedPoses: [BodyPose] = []
    private var trunkLeans: [Double] = []
    private let requiredCaptureCount = 45 // ~3 seconds at 15fps
    
    func processPose(_ pose: BodyPose) {
        // Only process if landmarks are visible enough
        let required: [BodyJoint.JointName] = [.leftShoulder, .rightShoulder, .leftHip, .rightHip]
        let isVisible = required.allSatisfy { pose.joint($0) != nil && pose.joint($0)!.confidence > 0.5 }
        
        if isVisible {
            capturedPoses.append(pose)
        }
    }
    
    func finish() -> AssessmentTestResult {
        guard !capturedPoses.isEmpty else {
            return AssessmentTestResult(id: UUID(), type: id, measurements: [:], overallQuality: .invalid)
        }
        
        var shoulderAngles: [Double] = []
        var hipAngles: [Double] = []
        var totalConf: Float = 0
        
        for pose in capturedPoses {
            if let leftS = pose.joint(.leftShoulder), let rightS = pose.joint(.rightShoulder),
               let leftH = pose.joint(.leftHip), let rightH = pose.joint(.rightHip) {
                
                // Absolute horizontal tilt angle (always positive)
                let shoulderAngle = abs(GeometryEngine.horizontalAngle(p1: leftS.position, p2: rightS.position))
                let hipAngle = abs(GeometryEngine.horizontalAngle(p1: leftH.position, p2: rightH.position))
                
                // Trunk lateral lean: angle from vertical (0 = perfectly upright)
                // Vector from hipMid to shoulderMid, measure deviation from vertical
                let shoulderMid = CGPoint(x: (leftS.position.x + rightS.position.x) / 2, y: (leftS.position.y + rightS.position.y) / 2)
                let hipMid = CGPoint(x: (leftH.position.x + rightH.position.x) / 2, y: (leftH.position.y + rightH.position.y) / 2)
                // dx, dy from hip to shoulder. In iOS coords Y=0 is top, so shoulder Y < hip Y (negative dy)
                let dx = shoulderMid.x - hipMid.x
                let dy = shoulderMid.y - hipMid.y // should be negative (shoulder is above hip)
                // Angle from vertical axis: atan2(|dx|, |dy|) — deviation from upright
                let trunkLean = atan2(abs(dx), abs(dy)) * 180 / .pi
                
                shoulderAngles.append(shoulderAngle)
                hipAngles.append(hipAngle)
                trunkLeans.append(trunkLean)
            }
            totalConf += pose.confidence
        }
        
        let avgShoulder = shoulderAngles.isEmpty ? 0 : shoulderAngles.reduce(0, +) / Double(shoulderAngles.count)
        let avgHip = hipAngles.isEmpty ? 0 : hipAngles.reduce(0, +) / Double(hipAngles.count)
        let avgTrunk = trunkLeans.isEmpty ? 0 : trunkLeans.reduce(0, +) / Double(trunkLeans.count)
        let avgConf = Double(totalConf / Float(max(1, capturedPoses.count)))
        
        let measurements: [String: MeasurementResult] = [
            "shoulderLevelAngle": MeasurementResult(
                value: avgShoulder,
                unit: "°",
                confidence: avgConf,
                quality: avgConf > 0.8 ? .high : .acceptable
            ),
            "pelvicLevelAngle": MeasurementResult(
                value: avgHip,
                unit: "°",
                confidence: avgConf,
                quality: avgConf > 0.8 ? .high : .acceptable
            ),
            "trunkLateralLean": MeasurementResult(
                value: avgTrunk,
                unit: "°",
                confidence: avgConf,
                quality: avgConf > 0.8 ? .high : .acceptable
            )
        ]
        
        return AssessmentTestResult(
            id: UUID(),
            type: id,
            measurements: measurements,
            overallQuality: capturedPoses.count >= requiredCaptureCount ? .high : .acceptable
        )
    }
    
    func reset() {
        capturedPoses.removeAll()
        trunkLeans.removeAll()
    }
}
