import SwiftUI

struct DebugPoseView: View {
    @StateObject private var viewModel = DebugPoseViewModel()
    
    var body: some View {
        ZStack {
            // Camera Feed
            CameraPreviewView(session: viewModel.cameraService.session)
                .ignoresSafeArea()
            
            // Skeleton Overlay
            if let pose = viewModel.poseDetector.currentPose {
                SkeletonView(pose: pose)
            }
            
            // Metrics HUD Overlay
            VStack {
                HStack(alignment: .top) {
                    // Left Column: Angles & Metrics
                    VStack(alignment: .leading, spacing: 12) {
                        HUDMetricRow(label: "Omuz Eğimi", value: viewModel.shoulderLevel, unit: "°", threshold: 3)
                        HUDMetricRow(label: "Kalça Eğimi", value: viewModel.hipLevel, unit: "°", threshold: 4)
                        HUDMetricRow(label: "Sol Diz", value: viewModel.leftKneeAngle, unit: "°", threshold: nil)
                        HUDMetricRow(label: "Sağ Diz", value: viewModel.rightKneeAngle, unit: "°", threshold: nil)
                    }
                    .padding(16)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 10)
                    
                    Spacer()
                    
                    // Right Column: System Status
                    VStack(alignment: .trailing, spacing: 10) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(viewModel.currentFPS > 20 ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)
                            Text("DEBUG HUD")
                                .font(.caption.bold())
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("FPS: \(String(format: "%.1f", viewModel.currentFPS))")
                                .font(.caption2.monospacedDigit())
                            
                            Text("Ort. Güvenilirlik: \(Int(viewModel.averageConfidence * 100))%")
                                .font(.caption2.monospacedDigit())
                                .foregroundColor(viewModel.averageConfidence > 0.8 ? .primary : .orange)
                        }
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding()
                
                Spacer()
                
                // Guidance HUD Bar
                HStack(spacing: 12) {
                    Image(systemName: guidanceIcon)
                        .font(.title2)
                        .foregroundColor(guidanceColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(guidanceMessage)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if !viewModel.missingJoints.isEmpty && viewModel.missingJoints.first != "İnsan Silüeti Bulunamadı" {
                            Text("Görünmeyenler: \(viewModel.missingJoints.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: guidanceColor.opacity(0.3), radius: 10, y: 5)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }
    
    private var guidanceMessage: String {
        if viewModel.missingJoints.contains("İnsan Silüeti Bulunamadı") {
            return "Kamera aranıyor..."
        }
        
        if viewModel.missingJoints.isEmpty {
            return "Pozisyon Mükemmel!"
        } else {
            return "Lütfen tam olarak kadraja girin."
        }
    }
    
    private var guidanceColor: Color {
        if viewModel.missingJoints.contains("İnsan Silüeti Bulunamadı") {
            return .gray
        }
        return viewModel.missingJoints.isEmpty ? .green : .orange
    }
    
    private var guidanceIcon: String {
        if viewModel.missingJoints.contains("İnsan Silüeti Bulunamadı") {
            return "video.slash.fill"
        }
        return viewModel.missingJoints.isEmpty ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
    }
}

struct HUDMetricRow: View {
    let label: String
    let value: Double
    let unit: String
    let threshold: Double? // For dynamic status indication
    
    var isWarning: Bool {
        guard let threshold = threshold else { return false }
        return abs(value) > threshold
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer(minLength: 20)
            
            HStack(spacing: 6) {
                Text(String(format: "%.1f", value) + unit)
                    .font(.body.monospacedDigit().bold())
                    .foregroundColor(.primary)
                
                if threshold != nil {
                    Image(systemName: isWarning ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundColor(isWarning ? .orange : .green)
                        .font(.caption)
                }
            }
        }
        .frame(minWidth: 160)
    }
}

#Preview {
    DebugPoseView()
}
