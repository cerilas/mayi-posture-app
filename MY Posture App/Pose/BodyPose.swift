import Foundation
import CoreGraphics

/// Represents a specific joint or landmark on the human body.
struct BodyJoint: Identifiable, Equatable {
    let id: JointName
    let position: CGPoint // Normalized coordinates (0,0) to (1,1)
    let confidence: Float
    
    enum JointName: String, CaseIterable {
        case head
        case neck
        case root
        case leftEar, rightEar
        case leftShoulder, rightShoulder
        case leftElbow, rightElbow
        case leftWrist, rightWrist
        case leftHip, rightHip
        case leftKnee, rightKnee
        case leftAnkle, rightAnkle
    }
}

/// Represents the entire body pose detected in a single frame.
struct BodyPose: Equatable {
    let joints: [BodyJoint.JointName: BodyJoint]
    let timestamp: Date
    
    var confidence: Float {
        guard !joints.isEmpty else { return 0 }
        let total = joints.values.reduce(0) { $0 + $1.confidence }
        return total / Float(joints.count)
    }
    
    func joint(_ name: BodyJoint.JointName) -> BodyJoint? {
        return joints[name]
    }
}
