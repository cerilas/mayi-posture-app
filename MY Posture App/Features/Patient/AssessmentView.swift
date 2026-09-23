import SwiftUI
import WebKit

// MARK: - Pose Skeleton Overlay

struct PoseSkeletonOverlay: View {
    let pose: BodyPose?
    let moduleID: String
    var smoothedAngle: Double = 0
    var isFrontCamera: Bool = true
    private let connections: [(BodyJoint.JointName, BodyJoint.JointName)] = [
        (.head, .neck),
        (.neck, .leftShoulder), (.neck, .rightShoulder),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle)
    ]

    var body: some View {
        GeometryReader { _ in
            if let pose = pose {
                Canvas { context, size in
                    let w = size.width
                    let h = size.height
                    func pt(_ name: BodyJoint.JointName) -> CGPoint? {
                        guard let j = pose.joint(name) else { return nil }
                        let x = isFrontCamera ? (1 - j.position.x) * w : j.position.x * w
                        return CGPoint(x: x, y: j.position.y * h)
                    }
                    for (a, b) in connections {
                        if let pA = pt(a), let pB = pt(b) {
                            var path = Path()
                            path.move(to: pA)
                            path.addLine(to: pB)
                            context.stroke(path, with: .color(.white.opacity(0.85)),
                                           style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        }
                    }
                    for joint in pose.joints.values {
                        let x = isFrontCamera ? (1 - joint.position.x) * w : joint.position.x * w
                        let y = joint.position.y * h
                        let rect = CGRect(x: x - 5, y: y - 5, width: 10, height: 10)
                        context.fill(Path(ellipseIn: rect),
                                     with: .color(Color(red: 0.31, green: 0.43, blue: 0.97)))
                        context.stroke(Path(ellipseIn: rect),
                                       with: .color(.white), style: StrokeStyle(lineWidth: 1.5))
                    }
                    
                    // MARK: - AR Angle Visualizations
                    
                    func drawBadge(_ text: String, at point: CGPoint, color: Color) {
                        var resolvedText = context.resolve(Text(text).font(.system(size: 13, weight: .bold, design: .rounded)))
                        resolvedText.shading = .color(.white)
                        let width: CGFloat = CGFloat(text.count * 8 + 20)
                        let textRect = CGRect(x: point.x - width/2, y: point.y - 14, width: width, height: 28)
                        context.fill(Path(roundedRect: textRect, cornerRadius: 8), with: .color(color.opacity(0.85)))
                        context.stroke(Path(roundedRect: textRect, cornerRadius: 8), with: .color(.white.opacity(0.4)), style: StrokeStyle(lineWidth: 1))
                        context.draw(resolvedText, at: point, anchor: .center)
                    }

                    let accent = Color(red: 0.31, green: 0.43, blue: 0.97)
                    
                    switch moduleID {
                    case "front_static_posture":
                        if let ls = pt(.leftShoulder), let rs = pt(.rightShoulder) {
                            // Omuzlar arası yatay referans çizgisi
                            var ref = Path()
                            ref.move(to: CGPoint(x: rs.x - 35, y: rs.y))
                            ref.addLine(to: CGPoint(x: ls.x + 35, y: rs.y))
                            context.stroke(ref, with: .color(accent.opacity(0.8)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                            
                            let dx = rs.x - ls.x
                            let dy = rs.y - ls.y
                            let rawAngle = min(abs(atan2(dy, dx) * 180 / .pi), 180 - abs(atan2(dy, dx) * 180 / .pi))
                            let displayAngle = smoothedAngle > 0 ? smoothedAngle : rawAngle
                            let isBalanced = displayAngle < 1.5
                            let badgeColor: Color = isBalanced ? Color.green : Color.orange
                            let title = isBalanced ? String(format: "Omuzlar Dengeli (%.1f°)", displayAngle) : String(format: "Omuz Eğimi: %.1f°", displayAngle)
                            
                            drawBadge(title, at: CGPoint(x: (ls.x + rs.x)/2, y: min(ls.y, rs.y) - 26), color: badgeColor)
                        }
                        
                    case "side_static_posture":
                        let earPt = pt(.leftEar) ?? pt(.rightEar) ?? pt(.head)
                        let shPt = pt(.leftShoulder) ?? pt(.rightShoulder)
                        if let ear = earPt, let sh = shPt {
                            // Omuzdan yukarı dikey çekül hattı
                            var ref = Path()
                            ref.move(to: sh)
                            ref.addLine(to: CGPoint(x: sh.x, y: ear.y - 25))
                            context.stroke(ref, with: .color(accent.opacity(0.7)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                            
                            // Omuz-kulak bağlantı hattı
                            var line = Path()
                            line.move(to: sh)
                            line.addLine(to: ear)
                            context.stroke(line, with: .color(accent.opacity(0.85)), style: StrokeStyle(lineWidth: 2))
                            
                            let rawAngle = abs(atan2(ear.x - sh.x, -(ear.y - sh.y)) * 180 / .pi)
                            let displayAngle = smoothedAngle > 0 ? smoothedAngle : rawAngle
                            let isNormal = displayAngle <= 10.0
                            let badgeColor: Color = isNormal ? Color.green : (displayAngle <= 15.0 ? Color.orange : Color.red)
                            let title = String(format: "İleri Baş: %.1f°", displayAngle)
                            
                            drawBadge(title, at: CGPoint(x: (ear.x + sh.x)/2 + 35, y: (ear.y + sh.y)/2), color: badgeColor)
                        }
                        
                    case "shoulder_flexion", "shoulder_abduction":
                        for (s, w_idx) in [(BodyJoint.JointName.leftShoulder, BodyJoint.JointName.leftWrist), (.rightShoulder, .rightWrist)] {
                            if let sh = pt(s), let wrist = pt(w_idx) {
                                var ref = Path()
                                ref.move(to: sh)
                                ref.addLine(to: CGPoint(x: sh.x, y: sh.y - 60))
                                context.stroke(ref, with: .color(accent), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                
                                let angle = abs(atan2(wrist.x - sh.x, -(wrist.y - sh.y)) * 180 / .pi)
                                drawBadge(String(format: "%.0f°", angle), at: CGPoint(x: wrist.x + 25, y: wrist.y), color: accent)
                            }
                        }
                        
                    case "squat_5_reps":
                        for (h, k, a) in [(BodyJoint.JointName.leftHip, BodyJoint.JointName.leftKnee, BodyJoint.JointName.leftAnkle), (.rightHip, .rightKnee, .rightAnkle)] {
                            if let hip = pt(h), let knee = pt(k), let ankle = pt(a) {
                                let a1 = atan2(hip.y - knee.y, hip.x - knee.x)
                                let a2 = atan2(ankle.y - knee.y, ankle.x - knee.x)
                                var angle = abs((a1 - a2) * 180 / .pi)
                                if angle > 180 { angle = 360 - angle }
                                drawBadge(String(format: "%.0f°", angle), at: CGPoint(x: knee.x - 30, y: knee.y), color: accent)
                            }
                        }
                        
                    default:
                        break
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - GIF View (Transparent)

struct GIFView: UIViewRepresentable {
    let dataName: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false // Transparan arka plan
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.isUserInteractionEnabled = false

        if let asset = NSDataAsset(name: dataName) {
            let base64String = asset.data.base64EncodedString()
            let html = """
            <!DOCTYPE html>
            <html>
            <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body, html { margin: 0; padding: 0; width: 100%; height: 100%; background-color: transparent; }
                img { width: 100%; height: 100%; object-fit: contain; }
            </style>
            </head>
            <body>
                <img src="data:image/gif;base64,\(base64String)" />
            </body>
            </html>
            """
            webView.loadHTMLString(html, baseURL: nil)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// MARK: - Movement Instruction Visual

struct MovementInstructionVisual: View {
    let moduleID: String

    var body: some View {
        Group {
            switch moduleID {
            case "front_static_posture":
                Image("front_static_posture")
                    .resizable()
                    .scaledToFit()
            case "side_static_posture":
                Image("side_static_posture")
                    .resizable()
                    .scaledToFit()
            case "shoulder_flexion":
                GIFView(dataName: "shoulder_flexion")
            case "shoulder_abduction":
                GIFView(dataName: "shoulder_abduction")
            case "squat_5_reps":
                GIFView(dataName: "squat_5_reps")
            default:
                Image(systemName: "figure.walk")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
}

// MARK: - Module Step Bar

struct ModuleStepBar: View {
    let current: Int
    let total: Int
    let title: String
    private let accent = Color(red: 0.31, green: 0.43, blue: 0.97)

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                ForEach(0..<total, id: \.self) { i in
                    Capsule()
                        .fill(i == current ? accent : Color.white.opacity(0.25))
                        .frame(width: i == current ? 20 : 8, height: 4)
                        .animation(.spring(response: 0.35), value: current)
                }
            }
            Text("\(current + 1) / \(total)  ·  \(title)")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

// (Eski ModuleTransitionOverlay kaldırıldı, yeni UX'e geçildi)

// MARK: - Assessment View

struct AssessmentView: View {
    /// Callback to return to the main flow (replaces @Environment(\.dismiss))
    var onDismiss: () -> Void
    /// Resolved from appointment code — nil means no backend logging
    var userId: String?
    var appointmentCode: String?

    @StateObject private var viewModel = AssessmentViewModel()
    private let accent = Color(red: 0.31, green: 0.43, blue: 0.97)

    var body: some View {
        ZStack {
            // Camera
            CameraPreviewView(session: viewModel.cameraService.session)
                .ignoresSafeArea()
                .blur(radius: viewModel.state == .instruction ? 15 : 0)
                .animation(.easeInOut(duration: 0.4), value: viewModel.state)

            // Posture Analysis Poster Grid & Plumb Line (Izgara ve Çekül Hattı)
            if viewModel.state != .instruction {
                PostureGridOverlay(isAligned: viewModel.postureGuidance.isReady)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.postureGuidance.isReady)
            }

            // Pose Skeleton (Talimat ekranında gizle)
            if viewModel.state != .instruction {
                PoseSkeletonOverlay(
                    pose: viewModel.poseDetector.currentPose,
                    moduleID: viewModel.currentModule.id,
                    smoothedAngle: viewModel.smoothedLiveAngle,
                    isFrontCamera: viewModel.isFrontCamera
                )
            }

            // Vignette
            VStack {
                LinearGradient(colors: [Color.black.opacity(0.75), Color.clear],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 160).ignoresSafeArea(edges: .top)
                Spacer()
                LinearGradient(colors: [Color.clear, Color.black.opacity(0.82)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 300).ignoresSafeArea(edges: .bottom)
            }

            // Main UI
            VStack(spacing: 0) {
                headerBar
                Spacer()
                bottomPanel
            }

            // Instruction Overlay (Hazırım Butonu ile)
            if viewModel.state == .instruction {
                instructionOverlay
                    .transition(.opacity)
            }

            // Results overlay
            if case .completed(let result) = viewModel.state {
                Color.black.opacity(0.6).ignoresSafeArea()
                AssessmentResultSummaryView(
                    result: result,
                    summary: viewModel.clinicalSummary,
                    saveStatus: viewModel.saveStatus,
                    onRetry: {
                        viewModel.retrySave()
                    },
                    onDismiss: {
                        viewModel.reset()
                        onDismiss()
                    }
                )
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.35), value: viewModel.state)
        .onAppear {
            viewModel.userId = userId
            viewModel.appointmentCode = appointmentCode
            viewModel.startAssessment()
        }
        .onDisappear { viewModel.cameraService.stop() }
    }

    // MARK: - Header

    private var headerBar: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                // Kapat Butonu
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.15)))
                }

                // Ön / Arka Kamera Çevirme Butonu
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.switchCamera()
                    }
                }) {
                    Image(systemName: "camera.rotate.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.15)))
                }

                Spacer()

                if case .capturing(let progress) = viewModel.state {
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.15)).frame(width: 80, height: 4)
                        Capsule().fill(accent)
                            .frame(width: max(80 * CGFloat(progress), 4), height: 4)
                            .animation(.linear(duration: 0.1), value: progress)
                    }
                } else {
                    Color.clear.frame(width: 80, height: 4)
                }

                Spacer()

                // Atla Butonu
                Button(action: {
                    withAnimation { viewModel.skipCurrentModule() }
                }) {
                    HStack(spacing: 5) {
                        Text("Atla")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                        Image(systemName: "forward.fill")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white.opacity(0.2)))
                }
            }
            .padding(.horizontal, 20)

            ModuleStepBar(
                current: viewModel.currentModuleIndex,
                total: viewModel.totalModuleCount,
                title: viewModel.currentModule.title
            )
        }
        .padding(.top, 54)
    }

    // MARK: - Bottom Panel

    private var bottomPanel: some View {
        VStack(spacing: 16) {
            // Sadece instruction'da değilken küçük kutuyu göster
            if viewModel.state != .instruction {
                if case .positioning = viewModel.state {
                    HStack(spacing: 0) {
                        Spacer()
                        VStack(spacing: 6) {
                            MovementInstructionVisual(moduleID: viewModel.currentModule.id)
                                .frame(width: 100, height: 140)
                                .offset(y: -10)
                                .padding(.bottom, -10)
                            
                            Text("Bu pozisyonu taklit edin")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.75))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.black.opacity(0.5)))
                        }
                        .padding(.trailing, 20)
                    }
                }

                Text(statusMessage)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                if case .positioning = viewModel.state {
                    positioningHint
                    
                    if viewModel.cameraService.isRecordingVideo {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .modifier(PulseEffect(isAnimating: true))
                            Text("Otomatik Video Kaydı Aktif")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.black.opacity(0.45)))
                    }
                    
                    // Fotoğraf Çek (Complete Module) Butonu - Manuel ve Tam Genişlik
                    Button(action: {
                        withAnimation {
                            viewModel.captureManualPhoto()
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "camera.circle.fill")
                                .font(.system(size: 26, weight: .bold))
                            Text(viewModel.currentModule.id.contains("squat") ? "Kayıt Başlat" : "Fotoğraf Çek")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(viewModel.postureGuidance.isReady ? accent : Color.white.opacity(0.15))
                        .cornerRadius(16)
                        .shadow(color: viewModel.postureGuidance.isReady ? accent.opacity(0.4) : .clear, radius: 10, x: 0, y: 4)
                    }
                    .disabled(!viewModel.postureGuidance.isReady)
                    .padding(.top, 4)
                } else if case .capturing = viewModel.state {
                    capturingInstructions
                } else if case .failed(let reason) = viewModel.state {
                    retryButton(reason: reason)
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 52)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Instruction Overlay

    private var instructionOverlay: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 40)
                    
                    // Görsel
                    MovementInstructionVisual(moduleID: viewModel.currentModule.id)
                        .frame(width: 180, height: 260)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .fill(Color.black.opacity(0.4))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: accent.opacity(0.3), radius: 30, x: 0, y: 0) // Glow
                        )
                    
                    // Başlık ve Talimatlar
                    VStack(spacing: 16) {
                        Text(viewModel.currentModule.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(viewModel.currentModule.instructions, id: \.self) { instruction in
                                HStack(alignment: .top, spacing: 12) {
                                    Circle().fill(accent).frame(width: 6, height: 6).padding(.top, 6)
                                    Text(instruction)
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.85))
                                        .multilineTextAlignment(.leading)
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Hazırım Butonu
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.confirmReady()
                        }
                    }) {
                        Text("Hazırım")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(accent)
                            .cornerRadius(16)
                            .shadow(color: accent.opacity(0.5), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.4).ignoresSafeArea())
    }

    // MARK: - Retry Button

    private func retryButton(reason: String) -> some View {
        VStack(spacing: 16) {
            Text(reason)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.retryCurrentModule()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .bold))
                    Text("Tekrar Dene")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red)
                .cornerRadius(14)
                .shadow(color: Color.red.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.skipCurrentModule()
                }
            }) {
                Text("Bu Aşamayı Geç")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.6))
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Positioning Hint

    private var positioningHint: some View {
        let guidance = viewModel.postureGuidance

        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: guidance.statusIcon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(guidance.statusColor)
                    .frame(width: 28, height: 28)

                Text(guidance.statusText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(guidance.statusColor.opacity(0.5), lineWidth: 1.5)
                )
        )
    }

    // MARK: - Capturing Instructions

    private var capturingInstructions: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(viewModel.currentModule.instructions, id: \.self) { instruction in
                HStack(alignment: .top, spacing: 10) {
                    Circle().fill(accent).frame(width: 5, height: 5).padding(.top, 6)
                    Text(instruction)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.65))
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.08)))
    }

    // MARK: - Helpers

    private var statusMessage: String {
        switch viewModel.state {
        case .instruction:   return "Talimatlar"
        case .idle:          return "Hazırlanıyor..."
        case .positioning:   return "Pozisyon Alın"
        case .capturing:     return "Ölçülüyor..."
        case .completed:     return "Tamamlandı"
        case .failed:        return "Ölçüm Başarısız"
        }
    }
}

#Preview {
    AssessmentView(onDismiss: {})
}

// MARK: - Pulse Effect

struct PulseEffect: ViewModifier {
    var isAnimating: Bool
    @State private var pulse: Bool = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(pulse ? 1.2 : 1.0)
            .opacity(pulse ? 0.5 : 1.0)
            .onChange(of: isAnimating) { newValue in
                if newValue {
                    withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                } else {
                    withAnimation {
                        pulse = false
                    }
                }
            }
            .onAppear {
                if isAnimating {
                    withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                }
            }
    }
}
