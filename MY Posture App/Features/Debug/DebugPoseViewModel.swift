import SwiftUI
import Combine

class DebugPoseViewModel: ObservableObject {
    @Published var cameraService = CameraService()
    @Published var poseDetector = VisionPoseDetector()
    
    @Published var shoulderLevel: Double = 0
    @Published var hipLevel: Double = 0
    @Published var leftKneeAngle: Double = 0
    @Published var rightKneeAngle: Double = 0
    
    // Performance Metrics
    @Published var currentFPS: Double = 0
    @Published var averageConfidence: Double = 0
    @Published var missingJoints: [String] = []
    
    private var lastFrameTime: Date = Date()
    private var frameCount: Int = 0
    private var fpsTimer: Timer?
    
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
                self?.calculateFPS()
                self?.updateMeasurements(pose)
            }
            .store(in: &cancellables)
            
        // Timer to reset FPS if frames stop arriving
        fpsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if Date().timeIntervalSince(self.lastFrameTime) > 1.0 {
                self.currentFPS = 0
            }
        }
    }
    
    func start() {
        cameraService.start()
    }
    
    func stop() {
        cameraService.stop()
    }
    
    private func updateMeasurements(_ pose: BodyPose?) {
        guard let pose = pose else { 
            self.averageConfidence = 0
            self.missingJoints = ["İnsan Silüeti Bulunamadı"]
            return 
        }
        
        analyzeMissingJoints(pose: pose)
        
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
    
    private func calculateFPS() {
        let now = Date()
        frameCount += 1
        
        let timeElapsed = now.timeIntervalSince(lastFrameTime)
        if timeElapsed >= 1.0 {
            currentFPS = Double(frameCount) / timeElapsed
            frameCount = 0
            lastFrameTime = now
        }
    }
    
    private func analyzeMissingJoints(pose: BodyPose) {
        let requiredJoints: [(BodyJoint.JointName, String)] = [
            (.head, "Baş"), (.leftShoulder, "Sol Omuz"), (.rightShoulder, "Sağ Omuz"),
            (.leftHip, "Sol Kalça"), (.rightHip, "Sağ Kalça"),
            (.leftKnee, "Sol Diz"), (.rightKnee, "Sağ Diz"),
            (.leftAnkle, "Sol Ayak Bileği"), (.rightAnkle, "Sağ Ayak Bileği")
        ]
        
        var missing: [String] = []
        var totalConfidence: Float = 0
        var detectedCount: Int = 0
        
        for (jointName, displayName) in requiredJoints {
            if let joint = pose.joint(jointName), joint.confidence > 0.3 {
                totalConfidence += joint.confidence
                detectedCount += 1
            } else {
                missing.append(displayName)
            }
        }
        
        self.missingJoints = missing
        if detectedCount > 0 {
            self.averageConfidence = Double(totalConfidence) / Double(detectedCount)
        } else {
            self.averageConfidence = 0
        }
    }
}
