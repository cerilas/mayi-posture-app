import SwiftUI

// MARK: - Pose Skeleton Overlay

struct PoseSkeletonOverlay: View {
    let pose: BodyPose?
    let moduleID: String
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
                        return CGPoint(x: (1 - j.position.x) * w, y: j.position.y * h)
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
                        let x = (1 - joint.position.x) * w
                        let y = joint.position.y * h
                        let rect = CGRect(x: x - 5, y: y - 5, width: 10, height: 10)
                        context.fill(Path(ellipseIn: rect),
                                     with: .color(Color(red: 0.31, green: 0.43, blue: 0.97)))
                        context.stroke(Path(ellipseIn: rect),
                                       with: .color(.white), style: StrokeStyle(lineWidth: 1.5))
                    }
                    
                    // MARK: - AR Angle Visualizations
                    
                    func drawText(_ text: String, at point: CGPoint, color: Color = .white) {
                        var resolvedText = context.resolve(Text(text).font(.system(size: 14, weight: .bold, design: .rounded)))
                        resolvedText.shading = .color(color)
                        let width: CGFloat = CGFloat(text.count * 9 + 8)
                        let textRect = CGRect(x: point.x - width/2, y: point.y - 12, width: width, height: 24)
                        context.fill(Path(roundedRect: textRect, cornerRadius: 6), with: .color(.black.opacity(0.65)))
                        context.draw(resolvedText, at: point, anchor: .center)
                    }

                    let accent = Color(red: 0.31, green: 0.43, blue: 0.97)
                    
                    switch moduleID {
                    case "front_static_posture":
                        if let ls = pt(.leftShoulder), let rs = pt(.rightShoulder) {
                            var ref = Path()
                            ref.move(to: CGPoint(x: rs.x - 30, y: rs.y))
                            ref.addLine(to: CGPoint(x: ls.x + 30, y: rs.y))
                            context.stroke(ref, with: .color(accent), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                            
                            let dx = rs.x - ls.x
                            let dy = rs.y - ls.y
                            let angle = min(abs(atan2(dy, dx) * 180 / .pi), 180 - abs(atan2(dy, dx) * 180 / .pi))
                            drawText(String(format: "%.1f°", angle), at: CGPoint(x: (ls.x + rs.x)/2, y: rs.y - 20), color: accent)
                        }
                        
                    case "side_static_posture":
                        let isLeft = pt(.leftEar) != nil && pt(.leftShoulder) != nil
                        if let ear = isLeft ? pt(.leftEar) : pt(.rightEar),
                           let sh = isLeft ? pt(.leftShoulder) : pt(.rightShoulder) {
                            
                            var ref = Path()
                            ref.move(to: sh)
                            ref.addLine(to: CGPoint(x: sh.x, y: ear.y - 20))
                            context.stroke(ref, with: .color(accent), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                            
                            var line = Path()
                            line.move(to: sh)
                            line.addLine(to: ear)
                            context.stroke(line, with: .color(accent.opacity(0.8)), style: StrokeStyle(lineWidth: 2))
                            
                            let angle = abs(atan2(ear.x - sh.x, -(ear.y - sh.y)) * 180 / .pi)
                            drawText(String(format: "%.1f°", angle), at: CGPoint(x: (ear.x + sh.x)/2 + 25, y: (ear.y + sh.y)/2), color: accent)
                        }
                        
                    case "shoulder_flexion", "shoulder_abduction":
                        for (s, w_idx) in [(BodyJoint.JointName.leftShoulder, BodyJoint.JointName.leftWrist), (.rightShoulder, .rightWrist)] {
                            if let sh = pt(s), let wrist = pt(w_idx) {
                                var ref = Path()
                                ref.move(to: sh)
                                ref.addLine(to: CGPoint(x: sh.x, y: sh.y - 60))
                                context.stroke(ref, with: .color(accent), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                
                                let angle = abs(atan2(wrist.x - sh.x, -(wrist.y - sh.y)) * 180 / .pi)
                                drawText(String(format: "%.0f°", angle), at: CGPoint(x: wrist.x + 25, y: wrist.y), color: accent)
                            }
                        }
                        
                    case "squat_5_reps":
                        for (h, k, a) in [(BodyJoint.JointName.leftHip, BodyJoint.JointName.leftKnee, BodyJoint.JointName.leftAnkle), (.rightHip, .rightKnee, .rightAnkle)] {
                            if let hip = pt(h), let knee = pt(k), let ankle = pt(a) {
                                let a1 = atan2(hip.y - knee.y, hip.x - knee.x)
                                let a2 = atan2(ankle.y - knee.y, ankle.x - knee.x)
                                var angle = abs((a1 - a2) * 180 / .pi)
                                if angle > 180 { angle = 360 - angle }
                                drawText(String(format: "%.0f°", angle), at: CGPoint(x: knee.x - 30, y: knee.y), color: accent)
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

// MARK: - Posture Silhouette

struct PostureSilhouetteView: View {
    let moduleID: String

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let style = StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            let white  = GraphicsContext.Shading.color(.white.opacity(0.75))
            let accent = GraphicsContext.Shading.color(Color(red: 0.31, green: 0.43, blue: 0.97))

            func stroke(_ p: Path, _ s: GraphicsContext.Shading = white) { ctx.stroke(p, with: s, style: style) }
            func fill(_ p: Path, _ s: GraphicsContext.Shading = white) { ctx.fill(p, with: s) }

            let cx = w / 2
            let headR: CGFloat = w * 0.09
            let headY  = h * 0.06
            let neckY  = headY + headR * 2 + h * 0.01
            let shY    = neckY + h * 0.06
            let hipY   = shY + h * 0.20
            let kneeY  = hipY + h * 0.18
            let ankleY = kneeY + h * 0.16
            let sw: CGFloat = w * 0.22
            let hw: CGFloat = w * 0.12

            // Head
            fill(Path(ellipseIn: CGRect(x: cx - headR, y: headY, width: headR * 2, height: headR * 2)))

            // Neck
            var n = Path(); n.move(to: CGPoint(x: cx, y: headY + headR * 2)); n.addLine(to: CGPoint(x: cx, y: shY)); stroke(n)

            // Shoulder bar
            var sh = Path(); sh.move(to: CGPoint(x: cx - sw, y: shY)); sh.addLine(to: CGPoint(x: cx + sw, y: shY)); stroke(sh)

            // Torso
            var t = Path(); t.move(to: CGPoint(x: cx, y: shY)); t.addLine(to: CGPoint(x: cx, y: hipY)); stroke(t)

            // Hip bar
            var hp = Path(); hp.move(to: CGPoint(x: cx - hw, y: hipY)); hp.addLine(to: CGPoint(x: cx + hw, y: hipY)); stroke(hp)

            switch moduleID {

            case "front_static_posture":
                var la = Path()
                la.move(to: CGPoint(x: cx - sw, y: shY))
                la.addLine(to: CGPoint(x: cx - sw - 4, y: shY + h * 0.09))
                la.addLine(to: CGPoint(x: cx - sw - 2, y: shY + h * 0.18))
                stroke(la)
                var ra = Path()
                ra.move(to: CGPoint(x: cx + sw, y: shY))
                ra.addLine(to: CGPoint(x: cx + sw + 4, y: shY + h * 0.09))
                ra.addLine(to: CGPoint(x: cx + sw + 2, y: shY + h * 0.18))
                stroke(ra)
                var ll = Path(); ll.move(to: CGPoint(x: cx - hw, y: hipY)); ll.addLine(to: CGPoint(x: cx - hw, y: ankleY)); stroke(ll)
                var rl = Path(); rl.move(to: CGPoint(x: cx + hw, y: hipY)); rl.addLine(to: CGPoint(x: cx + hw, y: ankleY)); stroke(rl)

            case "shoulder_flexion":
                var la = Path()
                la.move(to: CGPoint(x: cx - sw, y: shY))
                la.addLine(to: CGPoint(x: cx - sw + w * 0.02, y: shY - h * 0.08))
                la.addLine(to: CGPoint(x: cx - sw + w * 0.04, y: shY - h * 0.17))
                stroke(la, accent)
                var ra = Path()
                ra.move(to: CGPoint(x: cx + sw, y: shY))
                ra.addLine(to: CGPoint(x: cx + sw - w * 0.02, y: shY - h * 0.08))
                ra.addLine(to: CGPoint(x: cx + sw - w * 0.04, y: shY - h * 0.17))
                stroke(ra, accent)
                var ll = Path(); ll.move(to: CGPoint(x: cx - hw, y: hipY)); ll.addLine(to: CGPoint(x: cx - hw, y: ankleY)); stroke(ll)
                var rl = Path(); rl.move(to: CGPoint(x: cx + hw, y: hipY)); rl.addLine(to: CGPoint(x: cx + hw, y: ankleY)); stroke(rl)

            case "shoulder_abduction":
                var la = Path()
                la.move(to: CGPoint(x: cx - sw, y: shY))
                la.addLine(to: CGPoint(x: cx - sw - w * 0.12, y: shY - h * 0.06))
                la.addLine(to: CGPoint(x: cx - sw - w * 0.22, y: shY - h * 0.14))
                stroke(la, accent)
                var ra = Path()
                ra.move(to: CGPoint(x: cx + sw, y: shY))
                ra.addLine(to: CGPoint(x: cx + sw + w * 0.12, y: shY - h * 0.06))
                ra.addLine(to: CGPoint(x: cx + sw + w * 0.22, y: shY - h * 0.14))
                stroke(ra, accent)
                var ll = Path(); ll.move(to: CGPoint(x: cx - hw, y: hipY)); ll.addLine(to: CGPoint(x: cx - hw, y: ankleY)); stroke(ll)
                var rl = Path(); rl.move(to: CGPoint(x: cx + hw, y: hipY)); rl.addLine(to: CGPoint(x: cx + hw, y: ankleY)); stroke(rl)

            case "squat_5_reps":
                let sHipY  = hipY + h * 0.06
                let sKneeY = sHipY + h * 0.10
                let sAnkleY = sKneeY + h * 0.12
                var la = Path()
                la.move(to: CGPoint(x: cx - sw, y: shY + h * 0.04))
                la.addLine(to: CGPoint(x: cx, y: shY - h * 0.01))
                stroke(la, accent)
                var ra = Path()
                ra.move(to: CGPoint(x: cx + sw, y: shY + h * 0.04))
                ra.addLine(to: CGPoint(x: cx, y: shY - h * 0.01))
                stroke(ra, accent)
                var torsoAdj = Path()
                torsoAdj.move(to: CGPoint(x: cx, y: shY))
                torsoAdj.addLine(to: CGPoint(x: cx + w * 0.03, y: sHipY))
                stroke(torsoAdj)
                var adjHip = Path()
                adjHip.move(to: CGPoint(x: cx - hw, y: sHipY))
                adjHip.addLine(to: CGPoint(x: cx + hw, y: sHipY))
                stroke(adjHip)
                var ll = Path()
                ll.move(to: CGPoint(x: cx - hw, y: sHipY))
                ll.addLine(to: CGPoint(x: cx - hw - w * 0.04, y: sKneeY))
                ll.addLine(to: CGPoint(x: cx - hw, y: sAnkleY))
                stroke(ll)
                var rl = Path()
                rl.move(to: CGPoint(x: cx + hw, y: sHipY))
                rl.addLine(to: CGPoint(x: cx + hw + w * 0.04, y: sKneeY))
                rl.addLine(to: CGPoint(x: cx + hw, y: sAnkleY))
                stroke(rl)

            default:
                var la = Path(); la.move(to: CGPoint(x: cx - sw, y: shY)); la.addLine(to: CGPoint(x: cx - sw, y: shY + h * 0.18)); stroke(la)
                var ra = Path(); ra.move(to: CGPoint(x: cx + sw, y: shY)); ra.addLine(to: CGPoint(x: cx + sw, y: shY + h * 0.18)); stroke(ra)
                var ll = Path(); ll.move(to: CGPoint(x: cx - hw, y: hipY)); ll.addLine(to: CGPoint(x: cx - hw, y: ankleY)); stroke(ll)
                var rl = Path(); rl.move(to: CGPoint(x: cx + hw, y: hipY)); rl.addLine(to: CGPoint(x: cx + hw, y: ankleY)); stroke(rl)
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

// MARK: - Module Transition Overlay

/// Full-screen card shown for 2.5 s between assessment modules.
struct ModuleTransitionOverlay: View {
    let nextIndex: Int
    let total: Int
    let module: AssessmentModule

    @State private var appeared = false
    private let accent = Color.white // Değiştirildi: Yeşil arkaplanda beyaz daha iyi durur

    var body: some View {
        ZStack {
            // Yarı transparan yeşil arkaplan
            Color.green.opacity(0.70).ignoresSafeArea()

            VStack(spacing: 28) {
                // Step badge
                HStack(spacing: 6) {
                    ForEach(0..<total, id: \.self) { i in
                        Capsule()
                            .fill(i == nextIndex ? accent : Color.white.opacity(0.4))
                            .frame(width: i == nextIndex ? 24 : 8, height: 5)
                    }
                }

                // Silhouette
                PostureSilhouetteView(moduleID: module.id)
                    .frame(width: 110, height: 160)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(accent.opacity(0.3), lineWidth: 1)
                            )
                    )

                // Title block
                VStack(spacing: 8) {
                    Text("Sıradaki Aşama")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .tracking(2)
                        .foregroundColor(accent)

                    Text(module.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    // Instructions preview
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(module.instructions, id: \.self) { instruction in
                            HStack(alignment: .top, spacing: 10) {
                                Circle().fill(accent).frame(width: 5, height: 5).padding(.top, 5)
                                Text(instruction)
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .scaleEffect(appeared ? 1 : 0.92)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4)) { appeared = true }
        }
    }
}

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

            // Pose Skeleton
            PoseSkeletonOverlay(pose: viewModel.poseDetector.currentPose, moduleID: viewModel.currentModule.id)

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

            // Between-module transition overlay
            if viewModel.isTransitioning {
                let nextIdx = viewModel.currentModuleIndex + 1
                if nextIdx < viewModel.totalModuleCount {
                    ModuleTransitionOverlay(
                        nextIndex: nextIdx,
                        total: viewModel.totalModuleCount,
                        module: viewModel.protocolModules[nextIdx] // Corrected: Use the next module, not the current one
                    )
                    .transition(.opacity)
                }
            }

            // Results overlay
            if case .completed(let result) = viewModel.state {
                Color.black.opacity(0.6).ignoresSafeArea()
                AssessmentResultSummaryView(result: result) {
                    viewModel.reset()
                    onDismiss()
                }
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.35), value: viewModel.isTransitioning)
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
            HStack(alignment: .center) {
                // ✅ Uses closure callback instead of @Environment(\.dismiss)
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
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
            }
            .padding(.horizontal, 20)

            ModuleStepBar(
                current: viewModel.currentModuleIndex,
                total: viewModel.totalModuleCount,
                title: viewModel.currentModule.title
            )
        }
        .padding(.top, 12)
    }

    // MARK: - Bottom Panel

    private var bottomPanel: some View {
        VStack(spacing: 16) {
            if case .positioning = viewModel.state {
                HStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 6) {
                        PostureSilhouetteView(moduleID: viewModel.currentModule.id)
                            .frame(width: 90, height: 130)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.black.opacity(0.45))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                            )
                        Text("Bu pozisyonu taklit edin")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.45))
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
            } else if case .capturing = viewModel.state {
                capturingInstructions
            } else if case .failed(let reason) = viewModel.state {
                retryButton(reason: reason)
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 52)
        .frame(maxWidth: .infinity)
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
        let count = viewModel.detectedJointCount
        let isDetected = count > 0
        let isReady = count >= 8
        let statusColor: Color = isReady ? .green : (isDetected ? .yellow : .red)

        return VStack(spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                    .shadow(color: statusColor.opacity(0.8), radius: 4)

                Text(isReady
                     ? "Vücut algılandı — hazırlanıyor..."
                     : (isDetected
                        ? "Kısmen algılandı — biraz geri adım atın"
                        : "Vücut algılanamıyor — kameraya bakın"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.12)).frame(height: 4)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(statusColor)
                        .frame(width: geo.size.width * CGFloat(min(count, 14)) / 14.0, height: 4)
                        .animation(.spring(response: 0.3), value: count)
                }
            }
            .frame(height: 4)

            Text("\(count) / 14 eklem tespit edildi")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundColor(Color.white.opacity(0.4))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(statusColor.opacity(0.4), lineWidth: 1)
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
