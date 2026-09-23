import Foundation
import CoreGraphics

/// Implementation of the Side (Sagittal) Static Posture Assessment (Fizyoterapist Göz Muayenesi).
class SidePostureAssessment: AssessmentModule {
    let id = "side_static_posture"
    let title = "Yan Postür Analizi"
    let instructions = [
        "Kameraya doğru sağ veya sol profilinizi dönün.",
        "Kollarınızı serbest bırakın.",
        "Kendi baktığınız yöne (ufka) bakın, kameraya dönmeyin.",
        "5 saniye sabit kalın."
    ]
    
    private var capturedPoses: [BodyPose] = []
    private let minRequiredFrames = 10
    
    func processPose(_ pose: BodyPose) {
        // Yan postür için bir taraftaki kulak ve omuzun (veya kafa ve omuzun) görünmesi yeterlidir
        let hasLeftUpper = (pose.joint(.leftEar) != nil || pose.joint(.head) != nil) && pose.joint(.leftShoulder) != nil
        let hasRightUpper = (pose.joint(.rightEar) != nil || pose.joint(.head) != nil) && pose.joint(.rightShoulder) != nil
        
        if hasLeftUpper || hasRightUpper {
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
            // Hangi taraf daha net görünüyorsa onu seç
            let leftConf = [pose.joint(.leftEar), pose.joint(.leftShoulder), pose.joint(.leftHip)]
                .compactMap { $0?.confidence }.reduce(0, +)
            
            let rightConf = [pose.joint(.rightEar), pose.joint(.rightShoulder), pose.joint(.rightHip)]
                .compactMap { $0?.confidence }.reduce(0, +)
            
            let useLeft = leftConf >= rightConf
            
            let earJoint = useLeft ? (pose.joint(.leftEar) ?? pose.joint(.head)) : (pose.joint(.rightEar) ?? pose.joint(.head))
            let shoulderJoint = useLeft ? pose.joint(.leftShoulder) : pose.joint(.rightShoulder)
            let hipJoint = useLeft ? pose.joint(.leftHip) : pose.joint(.rightHip)
            
            if let ear = earJoint, let shoulder = shoulderJoint {
                // Kulak ile omuz arasındaki dikey sapma açısı (Forward Head Posture)
                // iOS koordinatlarında Y aşağı doğrudur (Y=0 üst).
                let dxHead = ear.position.x - shoulder.position.x
                let dyHead = ear.position.y - shoulder.position.y // Baş omuzdan yukarıdaysa negatiftir
                
                // Dikey eksenden sapma: atan2(|dx|, |dy|)
                let fhpAngle = atan2(abs(dxHead), abs(dyHead)) * 180 / .pi
                forwardHeadAngles.append(fhpAngle)
            }
            
            if let shoulder = shoulderJoint, let hip = hipJoint {
                let dxTrunk = shoulder.position.x - hip.position.x
                let dyTrunk = shoulder.position.y - hip.position.y
                let trunkAngle = atan2(abs(dxTrunk), abs(dyTrunk)) * 180 / .pi
                trunkLeans.append(trunkAngle)
            }
            
            totalConf += pose.confidence
        }
        
        let avgConf = Double(totalConf / Float(max(1, capturedPoses.count)))
        
        // 5 saniyelik verinin kırpılmış ortalaması (Trimmed Mean):
        // Anlık seğirme ve baş oynamalarını filtreler
        func robustAverageOf(_ values: [Double]) -> Double {
            guard !values.isEmpty else { return 0.0 }
            if values.count < 8 {
                let sorted = values.sorted()
                return sorted[sorted.count / 2]
            }
            let sorted = values.sorted()
            let trimCount = max(1, Int(Double(sorted.count) * 0.15))
            let validRange = sorted[trimCount..<(sorted.count - trimCount)]
            if validRange.isEmpty { return sorted[sorted.count / 2] }
            return validRange.reduce(0, +) / Double(validRange.count)
        }
        
        let finalFHP = robustAverageOf(forwardHeadAngles)
        let finalTrunk = robustAverageOf(trunkLeans)
        
        var measurements: [String: MeasurementResult] = [
            "forwardHeadAngle": MeasurementResult(
                value: (finalFHP * 10).rounded() / 10,
                unit: "°",
                confidence: avgConf,
                quality: .high
            )
        ]
        
        if !trunkLeans.isEmpty {
            measurements["sagittalTrunkLean"] = MeasurementResult(
                value: (finalTrunk * 10).rounded() / 10,
                unit: "°",
                confidence: avgConf,
                quality: .high
            )
        }
        
        let quality: MeasurementQuality = capturedPoses.count >= minRequiredFrames ? .high : .acceptable
        
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
