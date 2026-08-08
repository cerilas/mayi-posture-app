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
            
            // Metrics Overlay
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        MetricRow(label: "Shoulder Level", value: viewModel.shoulderLevel, unit: "°")
                        MetricRow(label: "Hip Level", value: viewModel.hipLevel, unit: "°")
                        MetricRow(label: "Left Knee Angle", value: viewModel.leftKneeAngle, unit: "°")
                        MetricRow(label: "Right Knee Angle", value: viewModel.rightKneeAngle, unit: "°")
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("DEBUG MODE")
                            .font(.caption)
                            .bold()
                            .padding(5)
                            .background(Color.red)
                            .cornerRadius(5)
                        
                        Text("FPS: \(String(format: "%.1f", 15.0))") // Placeholder
                            .font(.caption)
                        
                        if let pose = viewModel.poseDetector.currentPose {
                            Text("Pose Conf: \(Int(pose.confidence * 100))%")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                }
                
                Spacer()
                
                // Guidance Message
                Text(guidanceMessage)
                    .font(.title2)
                    .bold()
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(15)
                    .foregroundColor(.white)
                    .padding(.bottom, 40)
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
        guard let pose = viewModel.poseDetector.currentPose else {
            return "Kamera aranıyor..."
        }
        
        let requiredJoints: [BodyJoint.JointName] = [.head, .leftAnkle, .rightAnkle]
        let visibleJoints = requiredJoints.filter { pose.joint($0) != nil }
        
        if visibleJoints.count < requiredJoints.count {
            return "Lütfen biraz geriye gidin ve tüm vücudunuzun göründüğünden emin olun."
        } else {
            return "Pozisyon uygun."
        }
    }
}

struct MetricRow: View {
    let label: String
    let value: Double
    let unit: String
    
    var body: some View {
        HStack {
            Text(label + ":")
            Spacer()
            Text(String(format: "%.1f", value) + unit)
                .bold()
        }
        .frame(width: 200)
    }
}

#Preview {
    DebugPoseView()
}
