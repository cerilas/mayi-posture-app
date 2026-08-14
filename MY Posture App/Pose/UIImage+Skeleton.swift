import UIKit
import CoreGraphics

extension UIImage {
    
    /// Draws the given `BodyPose` on top of the image.
    func drawingSkeleton(pose: BodyPose?) -> UIImage {
        guard let pose = pose else { return self }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = self.scale
        let renderer = UIGraphicsImageRenderer(size: self.size, format: format)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Draw original image
            self.draw(at: .zero)
            
            // Configuration
            let lineWidth = self.size.width * 0.005
            let jointRadius = self.size.width * 0.008
            
            let connections: [(BodyJoint.JointName, BodyJoint.JointName)] = [
                (.head, .neck), (.neck, .root),
                (.neck, .leftShoulder), (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
                (.neck, .rightShoulder), (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
                (.root, .leftHip), (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
                (.root, .rightHip), (.rightHip, .rightKnee), (.rightKnee, .rightAnkle),
                (.leftShoulder, .rightShoulder), (.leftHip, .rightHip)
            ]
            
            // Denormalize function
            func denormalize(_ point: CGPoint) -> CGPoint {
                return CGPoint(x: point.x * self.size.width, y: point.y * self.size.height)
            }
            
            // Draw connections
            cgContext.setLineWidth(lineWidth)
            cgContext.setLineCap(.round)
            cgContext.setLineJoin(.round)
            
            for connection in connections {
                if let start = pose.joint(connection.0), let end = pose.joint(connection.1) {
                    let startPoint = denormalize(start.position)
                    let endPoint = denormalize(end.position)
                    
                    cgContext.move(to: startPoint)
                    cgContext.addLine(to: endPoint)
                    
                    if start.confidence > 0.5 && end.confidence > 0.5 {
                        cgContext.setStrokeColor(UIColor.cyan.withAlphaComponent(0.8).cgColor)
                    } else {
                        cgContext.setStrokeColor(UIColor.orange.withAlphaComponent(0.8).cgColor)
                    }
                    cgContext.strokePath()
                }
            }
            
            // Draw joints
            for jointName in BodyJoint.JointName.allCases {
                if let joint = pose.joint(jointName) {
                    let point = denormalize(joint.position)
                    
                    var color = UIColor.red
                    if joint.confidence > 0.8 { color = UIColor.green }
                    else if joint.confidence > 0.4 { color = UIColor.yellow }
                    
                    let radius = joint.confidence > 0.5 ? jointRadius * 1.5 : jointRadius
                    let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
                    
                    cgContext.setFillColor(color.cgColor)
                    cgContext.fillEllipse(in: rect)
                    
                    cgContext.setLineWidth(lineWidth * 0.5)
                    cgContext.setStrokeColor(UIColor.white.cgColor)
                    cgContext.strokeEllipse(in: rect)
                }
            }
        }
    }
}
