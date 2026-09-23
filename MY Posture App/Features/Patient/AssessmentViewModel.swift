import SwiftUI
import Combine
import AVFoundation
import CoreMotion

/// Fizyoterapist Göz Muayenesi Klinik Özeti
struct ClinicalPostureSummary {
    var shoulderTilt: Double = 0
    var shoulderStatus: String = "Dengeli"
    var shoulderColor: Color = .green
    
    var headTilt: Double = 0
    var headStatus: String = "Doğal Eksen"
    
    var forwardHeadAngle: Double = 0
    var forwardHeadStatus: String = "Doğal Eksen"
    var forwardHeadColor: Color = .green
    
    var trunkLean: Double? = nil
    var pelvicTilt: Double? = nil
}

/// Duruş ve Pozisyon Rehberliği Durumu
struct PostureGuidance: Equatable {
    var isReady: Bool = false
    var statusText: String = "Kameranın karşısına geçin"
    var statusIcon: String = "person.fill.viewfinder"
    var statusColor: Color = .yellow
    var holdProgress: Double = 0.0 // 0.0 ile 1.0 arası
}

class AssessmentViewModel: ObservableObject {
    @Published var state: AssessmentState = .idle
    @Published var cameraService = CameraService()
    @Published var poseDetector = VisionPoseDetector()
    @Published var currentInstruction: String = ""
    @Published var captureProgress: Double = 0
    @Published var currentModuleIndex: Int = 0
    /// Number of joints currently detected — used to drive UI feedback
    @Published var detectedJointCount: Int = 0
    
    /// Real-time smoothed angle for UI overlay
    @Published var smoothedLiveAngle: Double = 0
    
    /// Akıllı duruş doğrulama durumu
    @Published var postureGuidance = PostureGuidance()
    
    /// All completed test results
    @Published var completedResults: [AssessmentTestResult] = []
    @Published var clinicalSummary = ClinicalPostureSummary()
    
    /// Authenticated user info from appointment code lookup
    var userId: String?
    var appointmentCode: String?
    
    let protocolModules: [AssessmentModule]
    private var cancellables = Set<AnyCancellable>()
    private var captureTimer: Timer?
    
    /// Pozisyonun sabit ve doğru tutulduğu başlangıç anı (5 saniyelik kesin süre için)
    private var readyStartTime: Date?
    private let requiredHoldDuration: TimeInterval = 5.0
    private var currentHoldSnapshot: UIImage? = nil
    
    // MARK: - CoreMotion (Telefon Eğim Kontrolü)
    private let motionManager = CMMotionManager()
    @Published var isDeviceFlat: Bool = false
    
    private func startMotionMonitoring() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.25
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let data = data, let self = self else { return }
            // Y ekseni telefonun uzun kenarıdır. Dik portre modunda: |Y| ≈ 0.85 - 1.0.
            // Z ekseni ekrana diktir. Telefon yatağa yatırıldığında veya yüze tutulduğunda: |Z| > 0.75 ve |Y| < 0.45 olur.
            let flat = abs(data.acceleration.z) > 0.75 && abs(data.acceleration.y) < 0.45
            self.isDeviceFlat = flat
        }
    }
    
    private func stopMotionMonitoring() {
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
        }
        isDeviceFlat = false
    }
    
    deinit {
        stopMotionMonitoring()
    }
    
    var currentModule: AssessmentModule {
        guard currentModuleIndex < protocolModules.count else {
            return protocolModules.last ?? FrontPostureAssessment()
        }
        return protocolModules[currentModuleIndex]
    }
    
    var totalModuleCount: Int {
        protocolModules.count
    }
    
    var isFrontCamera: Bool {
        cameraService.cameraPosition == .front
    }
    
    init(modules: [AssessmentModule]? = nil) {
        if let customModules = modules {
            self.protocolModules = customModules
        } else {
            // Fizyoterapist göz muayenesi standardı: Varsayılan olarak Ön ve Yan Postür aktiftir.
            var activeModules: [AssessmentModule] = []
            let ud = UserDefaults.standard
            
            let useFront = ud.object(forKey: "enable_front_posture") == nil ? true : ud.bool(forKey: "enable_front_posture")
            if useFront { activeModules.append(FrontPostureAssessment()) }
            
            let useSide = ud.object(forKey: "enable_side_posture") == nil ? true : ud.bool(forKey: "enable_side_posture")
            if useSide { activeModules.append(SidePostureAssessment()) }
            
            let useFlexion = ud.object(forKey: "enable_shoulder_flexion") == nil ? true : ud.bool(forKey: "enable_shoulder_flexion")
            if useFlexion { activeModules.append(ShoulderROMAssessment(type: .flexion)) }
            
            let useAbduction = ud.object(forKey: "enable_shoulder_abduction") == nil ? true : ud.bool(forKey: "enable_shoulder_abduction")
            if useAbduction { activeModules.append(ShoulderROMAssessment(type: .abduction)) }
            
            let useSquat = ud.object(forKey: "enable_squat") == nil ? true : ud.bool(forKey: "enable_squat")
            if useSquat { activeModules.append(SquatAssessment()) }
            
            if activeModules.isEmpty {
                activeModules = [FrontPostureAssessment(), SidePostureAssessment()]
            }
            
            self.protocolModules = activeModules
        }
        
        self.currentInstruction = self.protocolModules.first?.instructions.first ?? ""
        setupBindings()
    }
    
    private func setupBindings() {
        cameraService.framePublisher
            .sink { [weak self] sampleBuffer in
                self?.poseDetector.processFrame(sampleBuffer)
            }
            .store(in: &cancellables)
        
        poseDetector.$currentPose
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pose in
                guard let self = self else { return }
                self.detectedJointCount = pose?.joints.count ?? 0
                self.handlePose(pose)
            }
            .store(in: &cancellables)
    }
    
    func startAssessment() {
        currentModuleIndex = 0
        detectedJointCount = 0
        completedResults = []
        temporarySnapshots.removeAll()
        temporaryVideos.removeAll()
        sessionVideoURL = nil
        clinicalSummary = ClinicalPostureSummary()
        readyStartTime = nil
        postureGuidance = PostureGuidance()
        state = .instruction
        cameraService.start()
        startMotionMonitoring()

        // Otomatik Video Kaydı (Ayarlarda açıksa kesintisiz kayıt başlar)
        let ud = UserDefaults.standard
        let shouldRecord = ud.object(forKey: "record_assessment_video") == nil ? true : ud.bool(forKey: "record_assessment_video")
        if shouldRecord && !cameraService.isRecordingVideo {
            cameraService.startVideoRecording()
        }
    }
    
    func switchCamera() {
        cameraService.switchCamera()
    }

    func confirmReady() {
        readyStartTime = nil
        postureGuidance = PostureGuidance()
        state = .positioning
    }
    
    private func handlePose(_ pose: BodyPose?) {
        guard let pose = pose else {
            if case .positioning = state {
                readyStartTime = nil
                postureGuidance = PostureGuidance(
                    isReady: false,
                    statusText: "Kameranın karşısına geçin",
                    statusIcon: "person.fill.viewfinder",
                    statusColor: .yellow,
                    holdProgress: 0
                )
            }
            return
        }
        
        // Canlı açı yumuşatma (EMA filtresi)
        updateLiveSmoothedAngle(pose)
        
        switch state {
        case .positioning:
            evaluatePostureAndHold(pose)
        case .capturing:
            currentModule.processPose(pose)
        default:
            break
        }
    }
    
    // MARK: - Akıllı Pozisyon ve Duruş Doğrulama
    
    private func evaluatePostureAndHold(_ pose: BodyPose) {
        // 0. Donanımsal Eğim Kontrolü: Telefonun Yatakta/Yatay Tutulmasını Engelleme
        if isDeviceFlat {
            resetHold(
                text: "Telefonu dik bir yere sabitleyin veya dik tutun (Yatarak ölçüm yapılamaz)",
                icon: "iphone",
                color: .red
            )
            return
        }

        // 1. Eklem Sayısı Kontrolü
        guard pose.joints.count >= 5 else {
            resetHold(text: "Kameranın karşısına geçin ve kadraja girin", icon: "person.fill.viewfinder", color: .yellow)
            return
        }
        
        // 2. Çok Yakınlık / Mesafe Kontrolü (Selfie / Yakın çekim engelleme)
        if let ls = pose.joint(.leftShoulder), let rs = pose.joint(.rightShoulder),
           ls.confidence > 0.25, rs.confidence > 0.25 {
            let shoulderWidth = abs(rs.position.x - ls.position.x)
            if shoulderWidth > 0.45 {
                resetHold(text: "Çok yakındasınız. Lütfen 2-3 adım geri çekilin", icon: "arrow.up.backward.and.arrow.down.forward", color: .orange)
                return
            }
        }
        
        // 3. Alt Gövde / Pelvis Varlığı (Kalça Olmadan Postür Analizi Yapılamaz)
        let leftHip = pose.joint(.leftHip)
        let rightHip = pose.joint(.rightHip)
        let hasHip = (leftHip?.confidence ?? 0 > 0.18) || (rightHip?.confidence ?? 0 > 0.18)
        
        guard hasHip else {
            resetHold(
                text: "Lütfen 2-3 adım geriye çekilin (Kalça ve bacaklar kadrajda görünmeli)",
                icon: "figure.walk",
                color: .yellow
            )
            return
        }

        // 4. Omurga Dikeyliği ve Yatar Pozisyon Tespiti (Anti-Lying Check)
        let shMidX: CGFloat
        let shMidY: CGFloat
        if let ls = pose.joint(.leftShoulder), let rs = pose.joint(.rightShoulder),
           ls.confidence > 0.15, rs.confidence > 0.15 {
            shMidX = (ls.position.x + rs.position.x) / 2.0
            shMidY = (ls.position.y + rs.position.y) / 2.0
        } else if let ls = pose.joint(.leftShoulder), ls.confidence > 0.20 {
            shMidX = ls.position.x
            shMidY = ls.position.y
        } else if let rs = pose.joint(.rightShoulder), rs.confidence > 0.20 {
            shMidX = rs.position.x
            shMidY = rs.position.y
        } else {
            resetHold(text: "Omuzlar görünmüyor. Lütfen dik durun", icon: "person.crop.rectangle", color: .yellow)
            return
        }

        let hipMidX: CGFloat
        let hipMidY: CGFloat
        if let lh = leftHip, let rh = rightHip, lh.confidence > 0.15, rh.confidence > 0.15 {
            hipMidX = (lh.position.x + rh.position.x) / 2.0
            hipMidY = (lh.position.y + rh.position.y) / 2.0
        } else if let lh = leftHip, lh.confidence > 0.20 {
            hipMidX = lh.position.x
            hipMidY = lh.position.y
        } else if let rh = rightHip, rh.confidence > 0.20 {
            hipMidX = rh.position.x
            hipMidY = rh.position.y
        } else {
            resetHold(text: "Kalça hizası net görünmüyor. Lütfen geri çekilin", icon: "figure.walk", color: .yellow)
            return
        }

        let torsoDx = abs(hipMidX - shMidX)
        let torsoDy = hipMidY - shMidY // Ayakta dik dururken kalça omuzun ALTINDADIR (hipMidY > shMidY, torsoDy > 0)

        // YATAR POZİSYON KONTROLÜ:
        // Eğer kalça omuzun belirgin şekilde altında değilse (torsoDy < 0.10) veya
        // gövde yatay eksene 35 dereceden fazla yatmışsa (torsoDx / torsoDy > 0.65), kişi yatakta yatmaktadır!
        if torsoDy < 0.10 || (torsoDx / max(0.01, torsoDy)) > 0.65 {
            resetHold(
                text: "Yatar pozisyon tespit edildi. Lütfen ayağa kalkın ve dik durun",
                icon: "figure.stand",
                color: .red
            )
            return
        }

        // 5. Oturur Pozisyon ve Uyluk Dikeylik Tespiti (Sitting / Lying Leg Check)
        for (hipName, kneeName) in [(BodyJoint.JointName.leftHip, BodyJoint.JointName.leftKnee), (.rightHip, .rightKnee)] {
            if let hip = pose.joint(hipName), let knee = pose.joint(kneeName),
               hip.confidence > 0.25, knee.confidence > 0.25 {
                let legDx = abs(knee.position.x - hip.position.x)
                let legDy = knee.position.y - hip.position.y
                
                // Ayakta uyluk aşağı iner (legDy >= 0.10). Otururken veya yatakta bacak uzatırken yataylaşır veya yukarı kalkar
                if legDy < 0.08 || (legDx > 0.08 && legDy < 0.12) {
                    resetHold(
                        text: "Oturur veya yatar pozisyon tespit edildi. Lütfen ayağa kalkın",
                        icon: "figure.stand",
                        color: .red
                    )
                    return
                }
            }
        }
        
        // 4. Modüle Göre Cephe (Oryantasyon) ve Duruş Doğrulaması
        switch currentModule.id {
        case "front_static_posture":
            // ÖN POSTÜR: Yüz ve gövde doğrudan kameraya karşıdan bakmalı
            guard let ls = pose.joint(.leftShoulder), let rs = pose.joint(.rightShoulder),
                  ls.confidence > 0.20, rs.confidence > 0.20 else {
                resetHold(text: "Omuzlar görünmüyor. Kameraya karşıdan bakın", icon: "person.crop.rectangle", color: .yellow)
                return
            }
            
            let shoulderWidth = abs(rs.position.x - ls.position.x)
            // Eğer omuz genişliği çok darsa hasta yan duruyordur
            if shoulderWidth < 0.10 {
                resetHold(text: "Lütfen yüzünüzü ve gövdenizi kameraya karşıdan dönün", icon: "arrow.triangle.2.circlepath", color: .orange)
                return
            }
            
        case "side_static_posture":
            // YAN POSTÜR: Hasta kameraya profil (sağ veya sol yanını) dönmüş olmalı
            // Eğer iki omuz da genişçe görünüyorsa hasta kameraya karşıdan bakıyordur
            if let ls = pose.joint(.leftShoulder), let rs = pose.joint(.rightShoulder),
               ls.confidence > 0.25, rs.confidence > 0.25 {
                let shoulderWidth = abs(rs.position.x - ls.position.x)
                if shoulderWidth >= 0.11 {
                    resetHold(text: "Lütfen kameraya sağ veya sol yanınızı (profilinizi) dönün", icon: "arrow.turn.up.forward.iphone", color: .orange)
                    return
                }
            }
            
            // Eğer iki kulak aynı anda net görünüyorsa hasta kameraya bakıyordur
            let hasBothEars = (pose.joint(.leftEar)?.confidence ?? 0 > 0.35) && (pose.joint(.rightEar)?.confidence ?? 0 > 0.35)
            if hasBothEars {
                resetHold(text: "Kameraya profil dönün, doğrudan ekrana bakmayın", icon: "arrow.turn.up.forward.iphone", color: .orange)
                return
            }
            
            // Yan postürde tek tarafın baş/kulak ve omuzu yeterlidir
            let hasEarOrHead = (pose.joint(.leftEar)?.confidence ?? 0 > 0.25) ||
                               (pose.joint(.rightEar)?.confidence ?? 0 > 0.25) ||
                               (pose.joint(.head)?.confidence ?? 0 > 0.25)
            let hasShoulder = (pose.joint(.leftShoulder)?.confidence ?? 0 > 0.25) ||
                              (pose.joint(.rightShoulder)?.confidence ?? 0 > 0.25)
            
            guard hasEarOrHead && hasShoulder else {
                resetHold(text: "Yan duruşunuzu netleştirin (baş ve omuz hizası)", icon: "figure.walk", color: .yellow)
                return
            }

        case "shoulder_flexion", "shoulder_abduction":
            // OMUZ TESTLERİ: Kollar hareket ettirileceği için gövde kameraya dönük olmalı
            guard let ls = pose.joint(.leftShoulder), let rs = pose.joint(.rightShoulder),
                  ls.confidence > 0.20, rs.confidence > 0.20 else {
                resetHold(text: "Omuzlar görünmüyor. Kameraya karşıdan bakın", icon: "person.crop.rectangle", color: .yellow)
                return
            }
            
            let shoulderWidth = abs(rs.position.x - ls.position.x)
            if shoulderWidth < 0.10 {
                resetHold(text: "Lütfen kameraya karşıdan bakın (yan durmayın)", icon: "arrow.triangle.2.circlepath", color: .orange)
                return
            }

        case "squat_5_reps":
            // SQUAT ANALİZİ: Hasta kameraya TAM KARŞIDAN bakmalı, bacaklar ve dizler görünmeli
            guard let ls = pose.joint(.leftShoulder), let rs = pose.joint(.rightShoulder),
                  ls.confidence > 0.20, rs.confidence > 0.20 else {
                resetHold(text: "Kameraya karşıdan bakın ve dik durun", icon: "person.crop.rectangle", color: .yellow)
                return
            }
            
            let shoulderWidth = abs(rs.position.x - ls.position.x)
            if shoulderWidth < 0.10 {
                resetHold(text: "Lütfen kameraya tam karşıdan bakın (yan durmayın)", icon: "arrow.triangle.2.circlepath", color: .orange)
                return
            }
            
            // Squat için kalça ve dizler kadrajda olmalı
            let hasHips = (pose.joint(.leftHip)?.confidence ?? 0 > 0.20) && (pose.joint(.rightHip)?.confidence ?? 0 > 0.20)
            let hasKnees = (pose.joint(.leftKnee)?.confidence ?? 0 > 0.20) && (pose.joint(.rightKnee)?.confidence ?? 0 > 0.20)
            
            guard hasHips && hasKnees else {
                resetHold(text: "Bacaklarınız ve dizleriniz kadrajda görünmeli", icon: "figure.walk", color: .yellow)
                return
            }

        default:
            break
        }
        
        // 5. Tüm Kriterler Geçti -> Manuel Çekim Bekleniyor
        postureGuidance = PostureGuidance(
            isReady: true,
            statusText: "Pozisyon uygun. Fotoğraf çekebilirsiniz.",
            statusIcon: "camera.viewfinder",
            statusColor: .green,
            holdProgress: 1.0
        )
    }
    
    private func resetHold(text: String, icon: String, color: Color) {
        readyStartTime = nil
        currentHoldSnapshot = nil
        if !currentModule.id.contains("squat") {
            currentModule.reset()
        }
        postureGuidance = PostureGuidance(
            isReady: false,
            statusText: text,
            statusIcon: icon,
            statusColor: color,
            holdProgress: 0
        )
    }
    
    private func updateLiveSmoothedAngle(_ pose: BodyPose) {
        var rawAngle: Double? = nil
        
        if currentModule.id == "front_static_posture" {
            if let ls = pose.joint(.leftShoulder), let rs = pose.joint(.rightShoulder) {
                let dx = rs.position.x - ls.position.x
                let dy = rs.position.y - ls.position.y
                rawAngle = abs(atan2(dy, dx) * 180 / .pi)
            }
        } else if currentModule.id == "side_static_posture" {
            let ear = pose.joint(.leftEar) ?? pose.joint(.rightEar) ?? pose.joint(.head)
            let sh = pose.joint(.leftShoulder) ?? pose.joint(.rightShoulder)
            if let ear = ear, let sh = sh {
                let dx = ear.position.x - sh.position.x
                let dy = ear.position.y - sh.position.y
                rawAngle = atan2(abs(dx), abs(dy)) * 180 / .pi
            }
        }
        
        if let raw = rawAngle {
            if smoothedLiveAngle == 0 {
                smoothedLiveAngle = raw
            } else {
                smoothedLiveAngle = smoothedLiveAngle * 0.75 + raw * 0.25
            }
        }
    }
    
    private func startCapture() {
        state = .capturing(progress: 0)
        captureProgress = 0
        smoothedLiveAngle = 0
        readyStartTime = nil
        
        let captureDuration: TimeInterval = currentModule.id.contains("squat") ? 12.0 : 3.0
        
        captureTimer?.invalidate()
        captureTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.captureProgress += 0.1 / captureDuration
            
            if self.captureProgress >= 1.0 {
                timer.invalidate()
                self.completeCurrentModule()
            } else if case .capturing = self.state {
                self.state = .capturing(progress: self.captureProgress)
            }
        }
    }
    
    // MARK: - Manual Capture
    
    @MainActor
    func captureManualPhoto() {
        guard let pose = poseDetector.currentPose else { return }
        
        if currentModule.id.contains("squat") {
            startCapture()
            return
        }
        
        // Statik postürler için anlık kareyi kaydet
        currentModule.reset()
        currentModule.processPose(pose)
        
        if let img = cameraService.takeSnapshot() {
            currentHoldSnapshot = generateCompositeSnapshot(from: img, with: pose)
        }
        
        completeCurrentModule()
    }
    
    @MainActor
    private func generateCompositeSnapshot(from img: UIImage, with pose: BodyPose?) -> UIImage {
        guard let pose = pose else { return img }
        
        // Ekran boyutunu al (UI'daki grid'in boyutlarına denk gelmesi için)
        let screenSize = UIScreen.main.bounds.size
        
        let compositeView = ZStack {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: screenSize.width, height: screenSize.height)
                .clipped()
            
            PostureGridOverlay(isAligned: postureGuidance.isReady)
            
            PoseSkeletonOverlay(
                pose: pose,
                moduleID: currentModule.id,
                smoothedAngle: smoothedLiveAngle,
                isFrontCamera: isFrontCamera
            )
        }
        .frame(width: screenSize.width, height: screenSize.height)
        
        let renderer = ImageRenderer(content: compositeView)
        renderer.scale = UIScreen.main.scale // Retina çözünürlük
        
        if let rendered = renderer.uiImage {
            return rendered
        }
        return img.drawingSkeleton(pose: pose)
    }
    
    private var temporarySnapshots: [UUID: UIImage] = [:]
    private var temporaryVideos: [UUID: URL] = [:]
    private var sessionVideoURL: URL? = nil
    
    @MainActor
    private func completeCurrentModule() {
        let result = currentModule.finish()
        
        if result.overallQuality == .invalid {
            self.state = .failed(reason: "Vücut net algılanamadı. Lütfen doğrudan kameraya bakarak tekrar deneyin.")
            return
        }
        
        if let snap = currentHoldSnapshot {
            temporarySnapshots[result.id] = snap
        } else if let image = cameraService.takeSnapshot() {
            temporarySnapshots[result.id] = self.generateCompositeSnapshot(from: image, with: self.poseDetector.currentPose)
        }
        currentHoldSnapshot = nil
        
        completedResults.append(result)
        
        // Pozisyonlar arasında video kaydı KESİLMEZ, arka planda tek parça devam eder.
        if currentModuleIndex < protocolModules.count - 1 {
            self.currentModuleIndex += 1
            self.readyStartTime = nil
            self.postureGuidance = PostureGuidance()
            self.state = .instruction
        } else {
            finishAssessment(finalResult: result)
        }
    }
    
    private func buildClinicalSummary() {
        var summary = ClinicalPostureSummary()
        
        for res in completedResults {
            if res.type == "front_static_posture" {
                if let sTilt = res.measurements["shoulderLevelAngle"]?.value {
                    summary.shoulderTilt = sTilt
                    let signed = res.measurements["shoulderSignedAngle"]?.value ?? 0
                    
                    if sTilt < 1.5 {
                        summary.shoulderStatus = "Omuzlar Dengeli (\(String(format: "%.1f°", sTilt)))"
                        summary.shoulderColor = .green
                    } else if signed > 0 {
                        summary.shoulderStatus = "Sağ Omuz \(String(format: "%.1f°", sTilt)) Yüksek"
                        summary.shoulderColor = .orange
                    } else {
                        summary.shoulderStatus = "Sol Omuz \(String(format: "%.1f°", sTilt)) Yüksek"
                        summary.shoulderColor = .orange
                    }
                }
                
                if let hTilt = res.measurements["headTiltAngle"]?.value {
                    summary.headTilt = hTilt
                    if hTilt < 2.0 {
                        summary.headStatus = "Doğal Eksen"
                    } else {
                        summary.headStatus = "Hafif Eğik (\(String(format: "%.1f°", hTilt)))"
                    }
                }
                
                if let trunk = res.measurements["trunkLateralLean"]?.value {
                    summary.trunkLean = trunk
                }
                if let pelvic = res.measurements["pelvicLevelAngle"]?.value {
                    summary.pelvicTilt = pelvic
                }
            } else if res.type == "side_static_posture" {
                if let fhp = res.measurements["forwardHeadAngle"]?.value {
                    summary.forwardHeadAngle = fhp
                    if fhp <= 10.0 {
                        summary.forwardHeadStatus = "Doğal Baş Duruşu (\(String(format: "%.1f°", fhp)))"
                        summary.forwardHeadColor = .green
                    } else if fhp <= 15.0 {
                        summary.forwardHeadStatus = "Hafif İleri Baş (\(String(format: "%.1f°", fhp)))"
                        summary.forwardHeadColor = .orange
                    } else {
                        summary.forwardHeadStatus = "Belirgin İleri Baş (\(String(format: "%.1f°", fhp)))"
                        summary.forwardHeadColor = .red
                    }
                }
            }
        }
        
        self.clinicalSummary = summary
    }
    
    func retryCurrentModule() {
        currentModule.reset()
        readyStartTime = nil
        postureGuidance = PostureGuidance()
        state = .positioning
    }
    
    func skipCurrentModule() {
        let result = currentModule.finish()
        if result.overallQuality != .invalid {
            completedResults.append(result)
        }
        
        if currentModuleIndex < protocolModules.count - 1 {
            self.currentModuleIndex += 1
            self.readyStartTime = nil
            self.postureGuidance = PostureGuidance()
            self.state = .instruction
        } else {
            finishAssessment(finalResult: result)
        }
    }

    @MainActor
    private func finishAssessment(finalResult: AssessmentTestResult) {
        buildClinicalSummary()
        state = .completed(result: finalResult)
        
        // Değerlendirme tamamen bittiğinde kesintisiz video kaydı durdurulur ve sıkıştırılır
        if cameraService.isRecordingVideo {
            cameraService.stopVideoRecording { [weak self] compressedURL in
                self?.sessionVideoURL = compressedURL
                self?.saveAllResults()
            }
        } else {
            saveAllResults()
        }
    }
    
    private func saveAllResults() {
        guard let userId = userId else {
            print("[AssessmentViewModel] No userId — skipping API save.")
            return
        }

        let capturedResults = completedResults
        let capturedCode = appointmentCode
        let snaps = temporarySnapshots
        let sessionVideo = sessionVideoURL

        Task {
            do {
                var finalResults = capturedResults
                for i in 0..<finalResults.count {
                    let resId = finalResults[i].id
                    if let image = snaps[resId] {
                        if let url = try? await PostureAPIService.shared.uploadPhoto(image) {
                            finalResults[i].snapshotUrl = url
                        }
                    }
                }
                
                var uploadedSessionVideoUrl: String? = nil
                if let videoURL = sessionVideo {
                    if let url = try? await PostureAPIService.shared.uploadVideo(videoURL) {
                        uploadedSessionVideoUrl = url
                        try? FileManager.default.removeItem(at: videoURL)
                    }
                }
                
                let response = try await PostureAPIService.shared.saveSession(
                    userId: userId,
                    appointmentCode: capturedCode,
                    videoUrl: uploadedSessionVideoUrl,
                    testResults: finalResults
                )
                print("[AssessmentViewModel] Session saved: \(response.sessionId), video: \(uploadedSessionVideoUrl ?? "none")")
            } catch {
                print("[AssessmentViewModel] API save failed: \(error.localizedDescription)")
            }
        }
    }
    
    func reset() {
        stopMotionMonitoring()
        captureTimer?.invalidate()
        if cameraService.isRecordingVideo {
            cameraService.stopVideoRecording { _ in }
        }
        protocolModules.forEach { $0.reset() }
        captureProgress = 0
        currentModuleIndex = 0
        detectedJointCount = 0
        readyStartTime = nil
        postureGuidance = PostureGuidance()
        completedResults = []
        temporarySnapshots.removeAll()
        temporaryVideos.removeAll()
        sessionVideoURL = nil
        currentHoldSnapshot = nil
        smoothedLiveAngle = 0
        state = .idle
    }
}
