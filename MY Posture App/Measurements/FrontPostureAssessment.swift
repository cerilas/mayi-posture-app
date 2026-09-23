import Foundation
import CoreGraphics

/// Implementation of the Front Static Posture Assessment (Fizyoterapist Göz Muayenesi).
class FrontPostureAssessment: AssessmentModule {
    let id = "front_static_posture"
    let title = "Ön Postür Analizi"
    let instructions = [
        "Kameraya karşı doğal ve dik durun.",
        "Kollarınızı yanlara serbest bırakın.",
        "Doğrudan karşıya bakın.",
        "5 saniye sabit kalın."
    ]
    
    private var capturedPoses: [BodyPose] = []
    private let minRequiredFrames = 10
    
    func processPose(_ pose: BodyPose) {
        // Ön postürde omuzların görünmesi temel yeterlilik şartıdır
        guard let leftS = pose.joint(.leftShoulder),
              let rightS = pose.joint(.rightShoulder),
              leftS.confidence > 0.25, rightS.confidence > 0.25 else {
            return
        }
        
        capturedPoses.append(pose)
    }
    
    func finish() -> AssessmentTestResult {
        guard !capturedPoses.isEmpty else {
            return AssessmentTestResult(id: UUID(), type: id, measurements: [:], overallQuality: .invalid)
        }
        
        var shoulderAngles: [Double] = []
        var shoulderSignedDiffs: [Double] = [] // Pozitif = Sağ omuz yüksek, Negatif = Sol omuz yüksek
        var headTilts: [Double] = []
        var hipAngles: [Double] = []
        var trunkLeans: [Double] = []
        var totalConf: Float = 0
        
        for pose in capturedPoses {
            guard let leftS = pose.joint(.leftShoulder),
                  let rightS = pose.joint(.rightShoulder) else { continue }
            
            // 1. Omuz Seviyesi (Horizontal Tilt)
            // iOS koordinat sisteminde Y=0 üsttür.
            // dy = rightS.position.y - leftS.position.y
            // Eğer rightS.y < leftS.y ise sağ omuz daha yukarıdadır.
            let dxS = rightS.position.x - leftS.position.x
            let dyS = rightS.position.y - leftS.position.y
            let rawShoulderAngle = atan2(dyS, dxS) * 180 / .pi
            let shoulderTilt = abs(rawShoulderAngle)
            shoulderAngles.append(shoulderTilt)
            shoulderSignedDiffs.append(rawShoulderAngle)
            
            // 2. Baş Eğikliği (Head Tilt)
            // Eğer iki kulak varsa kulaklar arası eğim, yoksa baş-boyun hattı
            if let leftEar = pose.joint(.leftEar), let rightEar = pose.joint(.rightEar),
               leftEar.confidence > 0.25, rightEar.confidence > 0.25 {
                let dxE = rightEar.position.x - leftEar.position.x
                let dyE = rightEar.position.y - leftEar.position.y
                let earAngle = abs(atan2(dyE, dxE) * 180 / .pi)
                // Başın omuzlara göre bağıl eğikliği
                let relativeHeadTilt = abs(earAngle - shoulderTilt)
                headTilts.append(relativeHeadTilt)
            } else if let head = pose.joint(.head), let neck = pose.joint(.neck),
                      head.confidence > 0.25, neck.confidence > 0.25 {
                let dxHN = head.position.x - neck.position.x
                let dyHN = head.position.y - neck.position.y // negatif (baş boyundan yukarıda)
                let tiltFromVertical = abs(atan2(dxHN, -dyHN) * 180 / .pi)
                headTilts.append(tiltFromVertical)
            }
            
            // 3. Pelvis ve Gövde Eğimi (Eğer kalçalar kadrajdaysa)
            if let leftH = pose.joint(.leftHip), let rightH = pose.joint(.rightHip),
               leftH.confidence > 0.25, rightH.confidence > 0.25 {
                let dxH = rightH.position.x - leftH.position.x
                let dyH = rightH.position.y - leftH.position.y
                let hipTilt = abs(atan2(dyH, dxH) * 180 / .pi)
                hipAngles.append(hipTilt)
                
                let shoulderMid = CGPoint(x: (leftS.position.x + rightS.position.x) / 2,
                                          y: (leftS.position.y + rightS.position.y) / 2)
                let hipMid = CGPoint(x: (leftH.position.x + rightH.position.x) / 2,
                                     y: (leftH.position.y + rightH.position.y) / 2)
                let dxTrunk = shoulderMid.x - hipMid.x
                let dyTrunk = shoulderMid.y - hipMid.y
                let trunkLean = abs(atan2(dxTrunk, -dyTrunk) * 180 / .pi)
                trunkLeans.append(trunkLean)
            }
            
            totalConf += pose.confidence
        }
        
        let avgConf = Double(totalConf / Float(max(1, capturedPoses.count)))
        
        // 5 saniyelik verinin kırpılmış ortalaması (Trimmed Mean):
        // En yüksek %15 ve en düşük %15'lik anlık seğirme/sapmaları atar, ortadaki %70'in ortalamasını alır.
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
        
        let finalShoulderTilt = robustAverageOf(shoulderAngles)
        let finalSignedShoulder = robustAverageOf(shoulderSignedDiffs)
        let finalHeadTilt = robustAverageOf(headTilts)
        let finalHipTilt = robustAverageOf(hipAngles)
        let finalTrunkLean = robustAverageOf(trunkLeans)
        
        var measurements: [String: MeasurementResult] = [
            "shoulderLevelAngle": MeasurementResult(
                value: (finalShoulderTilt * 10).rounded() / 10,
                unit: "°",
                confidence: avgConf,
                quality: .high
            ),
            "shoulderSignedAngle": MeasurementResult(
                value: (finalSignedShoulder * 10).rounded() / 10,
                unit: "°",
                confidence: avgConf,
                quality: .high
            )
        ]
        
        if !headTilts.isEmpty {
            measurements["headTiltAngle"] = MeasurementResult(
                value: (finalHeadTilt * 10).rounded() / 10,
                unit: "°",
                confidence: avgConf,
                quality: .high
            )
        }
        
        if !hipAngles.isEmpty {
            measurements["pelvicLevelAngle"] = MeasurementResult(
                value: (finalHipTilt * 10).rounded() / 10,
                unit: "°",
                confidence: avgConf,
                quality: .high
            )
        }
        
        if !trunkLeans.isEmpty {
            measurements["trunkLateralLean"] = MeasurementResult(
                value: (finalTrunkLean * 10).rounded() / 10,
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
