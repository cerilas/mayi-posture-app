import Vision
import CoreImage
import Combine

/// Implementation of pose detection using Apple's Vision framework.
class VisionPoseDetector: ObservableObject {
    @Published var currentPose: BodyPose?
    
    private let request = VNDetectHumanBodyPoseRequest()
    private var cancellables = Set<AnyCancellable>()
    
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([request])
            guard let observation = request.results?.first else {
                DispatchQueue.main.async {
                    self.currentPose = nil
                }
                return
            }
            
            let pose = try extractPose(from: observation)
            DispatchQueue.main.async {
                self.currentPose = pose
            }
        } catch {
            print("Vision error: \(error)")
        }
    }
    
    private func extractPose(from observation: VNHumanBodyPoseObservation) throws -> BodyPose {
        var joints: [BodyJoint.JointName: BodyJoint] = [:]
        
        let jointMapping: [VNHumanBodyPoseObservation.JointName: BodyJoint.JointName] = [
            .nose: .head,
            .leftEar: .leftEar,
            .rightEar: .rightEar,
            .neck: .neck,
            .root: .root,
            .leftShoulder: .leftShoulder,
            .rightShoulder: .rightShoulder,
            .leftElbow: .leftElbow,
            .rightElbow: .rightElbow,
            .leftWrist: .leftWrist,
            .rightWrist: .rightWrist,
            .leftHip: .leftHip,
            .rightHip: .rightHip,
            .leftKnee: .leftKnee,
            .rightKnee: .rightKnee,
            .leftAnkle: .leftAnkle,
            .rightAnkle: .rightAnkle
        ]
        
        for (visionName, internalName) in jointMapping {
            if let point = try? observation.recognizedPoint(visionName), point.confidence > 0.1 {
                joints[internalName] = BodyJoint(
                    id: internalName,
                    position: CGPoint(x: point.location.x, y: 1 - point.location.y), // Flip Y for SwiftUI
                    confidence: Float(point.confidence)
                )
            }
        }
        
        return BodyPose(joints: joints, timestamp: Date())
    }
}
