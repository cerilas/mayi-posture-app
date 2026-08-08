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
                        .stroke(Color.green, lineWidth: 3)
                    }
                }
                
                // Joints
                ForEach(BodyJoint.JointName.allCases, id: \.self) { name in
                    if let joint = pose.joint(name) {
                        Circle()
                            .fill(joint.confidence > 0.5 ? Color.blue : Color.red)
                            .frame(width: 10, height: 10)
                            .position(denormalize(joint.position, in: geometry.size))
                    }
                }
            }
        }
    }
    
    private func denormalize(_ point: CGPoint, in size: CGSize) -> CGPoint {
        return CGPoint(x: point.x * size.width, y: point.y * size.height)
    }
}
