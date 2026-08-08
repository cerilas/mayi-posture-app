import SwiftUI
import Combine

class AssessmentViewModel: ObservableObject {
    @Published var state: AssessmentState = .idle
    @Published var cameraService = CameraService()
    @Published var poseDetector = VisionPoseDetector()
    @Published var currentInstruction: String = ""
    @Published var captureProgress: Double = 0
    @Published var currentModuleIndex: Int = 0
    /// Number of joints currently detected — used to drive UI feedback
    @Published var detectedJointCount: Int = 0
    /// Authenticated user info from appointment code lookup
    var userId: String?
    var appointmentCode: String?
    
    let protocolModules: [AssessmentModule]
    private var cancellables = Set<AnyCancellable>()
    private var captureTimer: Timer?
    /// Fallback: if user is partially detected for >5 s, start capture anyway
    private var positioningFallbackTimer: Timer?
    
    var currentModule: AssessmentModule {
        protocolModules[currentModuleIndex]
    }
    
    var totalModuleCount: Int {
        protocolModules.count
    }
    
    init(modules: [AssessmentModule]? = nil) {
        if let customModules = modules {
            self.protocolModules = customModules
        } else {
            // Read admin panel settings from UserDefaults. Default is true if not set.
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
            
            // Eğer hepsi kapatıldıysa (hata olmaması için) en azından 1 tane koyalım
            if activeModules.isEmpty { activeModules.append(FrontPostureAssessment()) }
            
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
        state = .instruction
        cameraService.start()
    }
    
    func confirmReady() {
        state = .positioning
        startPositioningFallback()
    }
    
    /// If after 6 seconds a pose is partially visible (≥4 joints) but ankles aren't found,
    /// start capture anyway so the user isn't stuck.
    private func startPositioningFallback() {
        positioningFallbackTimer?.invalidate()
        positioningFallbackTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: false) { [weak self] _ in
            guard let self = self, case .positioning = self.state else { return }
            if self.detectedJointCount >= 4 {
                print("[AssessmentViewModel] Fallback trigger: \(self.detectedJointCount) joints detected, starting capture.")
                self.startCapture()
            }
        }
    }
    
    private func handlePose(_ pose: BodyPose?) {
        guard let pose = pose else { return }
        
        switch state {
        case .positioning:
            checkPosition(pose)
        case .capturing:
            currentModule.processPose(pose)
        default:
            break
        }
    }
    
    private func checkPosition(_ pose: BodyPose) {
        // Relaxed check: need head/neck + at least both hips + one knee
        // Ankles are unreliable on front camera — hips are sufficient to confirm full-body framing
        let hasHead  = pose.joint(.head)  != nil || pose.joint(.neck) != nil
        let hasHips  = pose.joint(.leftHip) != nil && pose.joint(.rightHip) != nil
        let hasKnee  = pose.joint(.leftKnee) != nil || pose.joint(.rightKnee) != nil
        
        if hasHead && hasHips && hasKnee {
            positioningFallbackTimer?.invalidate()
            startCapture()
        }
    }
    
    private func startCapture() {
        state = .capturing(progress: 0)
        captureProgress = 0
        
        // Capture window varies by module (static vs dynamic)
        let captureDuration: TimeInterval = currentModule.id.contains("squat") ? 15.0 : 4.0
        
        captureTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.captureProgress += 0.1 / captureDuration
            
            if self.captureProgress >= 1.0 {
                timer.invalidate()
                self.completeCurrentModule()
            }
            
            if case .capturing = self.state {
                self.state = .capturing(progress: self.captureProgress)
            }
        }
    }
    
    private var results: [AssessmentTestResult] = []
    
    private func completeCurrentModule() {
        let result = currentModule.finish()
        
        // Eğer ölçüm kalitesi düşükse kaydetme ve hata durumuna düş
        if result.overallQuality == .low || result.overallQuality == .invalid {
            self.state = .failed(reason: "Ölçüm tamamlanamadı veya kalitesi çok düşük. Lütfen ekrana tam sığdığınızdan emin olun.")
            return
        }
        
        results.append(result)
        
        if currentModuleIndex < protocolModules.count - 1 {
            // Bir sonraki hareketin talimat ekranına geç
            self.currentModuleIndex += 1
            self.state = .instruction
        } else {
            saveAllResults()
            state = .completed(result: result)
        }
    }
    
    func retryCurrentModule() {
        currentModule.reset()
        state = .positioning
        startPositioningFallback()
    }
    
    func skipCurrentModule() {
        // O anki tamamlanamamış / düşük kaliteli sonucu listeye ekle ve zorla geç
        let result = currentModule.finish()
        results.append(result)
        
        if currentModuleIndex < protocolModules.count - 1 {
            self.currentModuleIndex += 1
            self.state = .instruction
        } else {
            saveAllResults()
            state = .completed(result: result)
        }
    }
    
    private func saveAllResults() {
        guard let userId = userId else {
            print("[AssessmentViewModel] No userId — skipping API save (no appointment code was resolved).")
            return
        }

        let capturedResults = results
        let capturedCode = appointmentCode

        Task {
            do {
                let response = try await PostureAPIService.shared.saveSession(
                    userId: userId,
                    appointmentCode: capturedCode,
                    testResults: capturedResults
                )
                print("[AssessmentViewModel] Session saved: \(response.sessionId)")
            } catch {
                print("[AssessmentViewModel] API save failed: \(error.localizedDescription)")
                // Sessizce geç: sonuçlar halâ ekranda gösterilecek
            }
        }
    }
    
    func reset() {
        captureTimer?.invalidate()
        positioningFallbackTimer?.invalidate()
        protocolModules.forEach { $0.reset() }
        captureProgress = 0
        currentModuleIndex = 0
        detectedJointCount = 0
        state = .idle
    }
}
