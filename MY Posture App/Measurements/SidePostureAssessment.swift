import Foundation
import CoreGraphics

/// Implementation of the Side (Sagittal) Static Posture Assessment.
class SidePostureAssessment: AssessmentModule {
    let id = "side_static_posture"
    let title = "Yan Postür Analizi"
    let instructions = [
        "Sağ veya sol yanınızı dönün.",
        "Kollarınızı serbest bırakın.",
        "Karşıya doğru dik bakın.",
        "Hareket etmeyin."
    ]
    
    private var capturedPoses: [BodyPose] = []
    private let requiredCaptureCount = 45 // ~3 seconds at 15fps
    
    func processPose(_ pose: BodyPose) {
        // Require at least one side to be clearly visible: (Ear, Shoulder, Hip)
        let hasLeftSide = pose.joint(.leftEar) != nil && pose.joint(.leftShoulder) != nil && pose.joint(.leftHip) != nil
        let hasRightSide = pose.joint(.rightEar) != nil && pose.joint(.rightShoulder) != nil && pose.joint(.rightHip) != nil
        
        if hasLeftSide || hasRightSide {
            capturedPoses.append(pose)
        }
    }
    
    func finish() -> AssessmentTestResult {
        guard !capturedPoses.isEmpty else {
            return AssessmentTestResult(id: UUID(), type: id, measurements: [:], overallQuality: .invalid)
        }
        
        var forwardHeadAngles: [Double] = []
        var trunkLeans: [Double] = []
        var totalConf: Float = 0
        
        for pose in capturedPoses {
            // Determine which side is more visible
            let leftConf = [pose.joint(.leftEar), pose.joint(.leftShoulder), pose.joint(.leftHip)]
                .compactMap { $0?.confidence }.reduce(0, +)
            
            let rightConf = [pose.joint(.rightEar), pose.joint(.rightShoulder), pose.joint(.rightHip)]
                .compactMap { $0?.confidence }.reduce(0, +)
            
            let useLeft = leftConf >= rightConf
            
            if let ear = useLeft ? pose.joint(.leftEar) : pose.joint(.rightEar),
               let shoulder = useLeft ? pose.joint(.leftShoulder) : pose.joint(.rightShoulder),
               let hip = useLeft ? pose.joint(.leftHip) : pose.joint(.rightHip) {
                
                // Angle relative to vertical (which is 90 degrees in our coordinate system where horizontal is 0)
                // We want to know how far forward the ear is relative to the shoulder.
                // GeometryEngine.horizontalAngle returns angle from positive X axis.
                // Vertical (top to bottom) is 270 or 90 depending on Y axis.
                // Since Y is flipped for SwiftUI (0 at top), shoulder to ear vector (shoulder is bottom, ear is top)
                // goes in -Y direction. Let's compute manually to be safe.
                
                // dx, dy from Shoulder to Ear
                let dxHead = ear.position.x - shoulder.position.x
                let dyHead = ear.position.y - shoulder.position.y // Ear Y < Shoulder Y (so dy is negative)
                
                // We want the angle from the vertical axis.
                // Vertical axis vector is (0, -1) going upwards.
                // Angle = atan2(dx, -dy) in degrees
                let headAngle = atan2(dxHead, -dyHead) * 180 / .pi
                
                // Trunk Lean (Shoulder to Hip)
                let dxTrunk = shoulder.position.x - hip.position.x
                let dyTrunk = shoulder.position.y - hip.position.y
                let trunkAngle = atan2(dxTrunk, -dyTrunk) * 180 / .pi
                
                // Make angles absolute because it depends on which side they are facing
                forwardHeadAngles.append(abs(headAngle))
                trunkLeans.append(abs(trunkAngle))
            }
            totalConf += pose.confidence
        }
        
        let avgFHP = forwardHeadAngles.isEmpty ? 0 : forwardHeadAngles.reduce(0, +) / Double(forwardHeadAngles.count)
        let avgTrunk = trunkLeans.isEmpty ? 0 : trunkLeans.reduce(0, +) / Double(trunkLeans.count)
        let avgConf = Double(totalConf / Float(max(1, capturedPoses.count)))
        
        // Quality logic
        let quality: MeasurementQuality
        if capturedPoses.count < requiredCaptureCount / 2 {
            quality = .low
        } else if avgConf > 0.8 {
            quality = .high
        } else {
            quality = .acceptable
        }
        
        let measurements: [String: MeasurementResult] = [
            "forwardHeadAngle": MeasurementResult(
                value: avgFHP,
                unit: "°",
                confidence: avgConf,
                quality: (avgFHP > 15) ? .acceptable : .high
            ),
            "sagittalTrunkLean": MeasurementResult(
                value: avgTrunk,
                unit: "°",
                confidence: avgConf,
                quality: (avgTrunk > 10) ? .acceptable : .high
            )
        ]
        
        return AssessmentTestResult(
            id: UUID(),
            type: id,
            measurements: measurements,
            overallQuality: quality
        )
    }
    
    func reset() {
        capturedPoses.removeAll()
    }
}
