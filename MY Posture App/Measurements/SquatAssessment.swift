import Foundation

/// Assessment module for 5-Repetition Squat.
class SquatAssessment: AssessmentModule {
    let id = "squat_5_reps"
    let title = "5 Tekrar Squat"
    let instructions = [
        "Ayaklarınızı omuz genişliğinde açın.",
        "Kontrollü bir şekilde 5 kez çömelip kalkın.",
        "Kollarınızı öne doğru uzatabilirsiniz."
    ]
    
    private let stateMachine = MovementStateMachine(descending: 160, bottom: 110, standing: 170)
    private var maxKneeFlexionLeft: Double = 0
    private var maxKneeFlexionRight: Double = 0
    private var maxTrunkShift: Double = 0
    private var confidences: [Float] = []
    
    func processPose(_ pose: BodyPose) {
        guard let leftHip = pose.joint(.leftHip),
              let leftKnee = pose.joint(.leftKnee),
              let leftAnkle = pose.joint(.leftAnkle),
              let rightHip = pose.joint(.rightHip),
              let rightKnee = pose.joint(.rightKnee),
              let rightAnkle = pose.joint(.rightAnkle) else { return }
        
        let leftKneeAngle = GeometryEngine.angle(a: leftHip.position, b: leftKnee.position, c: leftAnkle.position)
        let rightKneeAngle = GeometryEngine.angle(a: rightHip.position, b: rightKnee.position, c: rightAnkle.position)
        
        // Dynamic balance: Trunk shift during squat
        let shoulderMid = (pose.joint(.leftShoulder) != nil && pose.joint(.rightShoulder) != nil) ? 
            CGPoint(x: (pose.joint(.leftShoulder)!.position.x + pose.joint(.rightShoulder)!.position.x)/2, y: (pose.joint(.leftShoulder)!.position.y + pose.joint(.rightShoulder)!.position.y)/2) : nil
        let hipMid = CGPoint(x: (leftHip.position.x + rightHip.position.x)/2, y: (leftHip.position.y + rightHip.position.y)/2)
        
        if let sm = shoulderMid {
            let shift = sm.x - hipMid.x
            maxTrunkShift = max(maxTrunkShift, abs(shift))
        }
        
        let avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2.0
        let (_, repCompleted) = stateMachine.update(currentValue: avgKneeAngle)
        
        // Track maximum flexion (minimum angle)
        if leftKneeAngle < (maxKneeFlexionLeft == 0 ? 180 : maxKneeFlexionLeft) {
            maxKneeFlexionLeft = leftKneeAngle
        }
        if rightKneeAngle < (maxKneeFlexionRight == 0 ? 180 : maxKneeFlexionRight) {
            maxKneeFlexionRight = rightKneeAngle
        }
        
        confidences.append(pose.confidence)
    }
    
    func finish() -> AssessmentTestResult {
        let avgConf = Double(confidences.reduce(0, +) / Float(max(1, confidences.count)))
        
        let measurements: [String: MeasurementResult] = [
            "completedRepetitions": MeasurementResult(
                value: Double(stateMachine.repetitionCount),
                unit: "",
                confidence: 1.0,
                quality: .high
            ),
            "maxLeftKneeFlexion": MeasurementResult(
                value: maxKneeFlexionLeft,
                unit: "°",
                confidence: avgConf,
                quality: avgConf > 0.7 ? .high : .acceptable
            ),
            "maxRightKneeFlexion": MeasurementResult(
                value: maxKneeFlexionRight,
                unit: "°",
                confidence: avgConf,
                quality: avgConf > 0.7 ? .high : .acceptable
            ),
            "maxTrunkShift": MeasurementResult(
                value: maxTrunkShift * 100, // Convert normalized to "units"
                unit: "%",
                confidence: avgConf,
                quality: .acceptable
            )
        ]
        
        return AssessmentTestResult(
            id: UUID(),
            type: id,
            measurements: measurements,
            overallQuality: stateMachine.repetitionCount >= 5 ? .high : .low
        )
    }
    
    func reset() {
        stateMachine.reset()
        maxKneeFlexionLeft = 0
        maxKneeFlexionRight = 0
        maxTrunkShift = 0
        confidences.removeAll()
    }
}
