import SwiftUI
import Combine

class DebugPoseViewModel: ObservableObject {
    @Published var cameraService = CameraService()
    @Published var poseDetector = VisionPoseDetector()
    
    @Published var shoulderLevel: Double = 0
    @Published var hipLevel: Double = 0
    @Published var leftKneeAngle: Double = 0
    @Published var rightKneeAngle: Double = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        cameraService.framePublisher
            .sink { [weak self] sampleBuffer in
                self?.poseDetector.processFrame(sampleBuffer)
            }
            .store(in: &cancellables)
        
        poseDetector.$currentPose
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pose in
                self?.updateMeasurements(pose)
            }
            .store(in: &cancellables)
    }
    
    func start() {
        cameraService.start()
    }
    
    func stop() {
        cameraService.stop()
    }
    
    private func updateMeasurements(_ pose: BodyPose?) {
        guard let pose = pose else { return }
        
        // Shoulder Level
        if let left = pose.joint(.leftShoulder), let right = pose.joint(.rightShoulder) {
            shoulderLevel = GeometryEngine.horizontalAngle(p1: left.position, p2: right.position)
        }
        
        // Hip Level
        if let left = pose.joint(.leftHip), let right = pose.joint(.rightHip) {
            hipLevel = GeometryEngine.horizontalAngle(p1: left.position, p2: right.position)
        }
        
        // Left Knee Angle
        if let hip = pose.joint(.leftHip), let knee = pose.joint(.leftKnee), let ankle = pose.joint(.leftAnkle) {
            leftKneeAngle = GeometryEngine.angle(a: hip.position, b: knee.position, c: ankle.position)
        }
        
        // Right Knee Angle
        if let hip = pose.joint(.rightHip), let knee = pose.joint(.rightKnee), let ankle = pose.joint(.rightAnkle) {
            rightKneeAngle = GeometryEngine.angle(a: hip.position, b: knee.position, c: ankle.position)
        }
    }
}
