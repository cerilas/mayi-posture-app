import SwiftUI

struct SkeletonView: View {
    let pose: BodyPose
    
    private let connections: [(BodyJoint.JointName, BodyJoint.JointName)] = [
        (.head, .neck), (.neck, .root),
        (.neck, .leftShoulder), (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.neck, .rightShoulder), (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.root, .leftHip), (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.root, .rightHip), (.rightHip, .rightKnee), (.rightKnee, .rightAnkle),
        (.leftShoulder, .rightShoulder), (.leftHip, .rightHip)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Connections
                ForEach(0..<connections.count, id: \.self) { index in
                    let connection = connections[index]
                    if let start = pose.joint(connection.0), let end = pose.joint(connection.1) {
                        Path { path in
                            path.move(to: denormalize(start.position, in: geometry.size))
                            path.addLine(to: denormalize(end.position, in: geometry.size))
                        }
                        .stroke(
                            (start.confidence > 0.5 && end.confidence > 0.5) ? Color.cyan.opacity(0.8) : Color.orange.opacity(0.8),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    }
                }
                
                // Joints
                ForEach(BodyJoint.JointName.allCases, id: \.self) { name in
                    if let joint = pose.joint(name) {
                        Circle()
                            .fill(jointColor(for: joint.confidence))
                            .frame(width: joint.confidence > 0.5 ? 12 : 8, height: joint.confidence > 0.5 ? 12 : 8)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 1.5)
                            )
                            .shadow(color: .black.opacity(0.4), radius: 2)
                            .position(denormalize(joint.position, in: geometry.size))
                    }
                }
            }
        }
    }
    
    private func denormalize(_ point: CGPoint, in size: CGSize) -> CGPoint {
        return CGPoint(x: point.x * size.width, y: point.y * size.height)
    }
    
    private func jointColor(for confidence: Float) -> Color {
        if confidence > 0.8 { return .green }
        if confidence > 0.4 { return .yellow }
        return .red
    }
}
