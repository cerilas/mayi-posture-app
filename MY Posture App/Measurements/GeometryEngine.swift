import Foundation
import CoreGraphics

/// Utility for performing geometric calculations on body landmarks.
struct GeometryEngine {
    
    /// Calculates the angle in degrees between three points (A-B-C), with B as the vertex.
    static func angle(a: CGPoint, b: CGPoint, c: CGPoint) -> Double {
        let v1 = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let v2 = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        
        let angle1 = atan2(v1.dy, v1.dx)
        let angle2 = atan2(v2.dy, v2.dx)
        
        var angle = (angle1 - angle2) * 180 / .pi
        if angle < 0 { angle += 360 }
        if angle > 180 { angle = 360 - angle }
        
        return angle
    }
    
    /// Calculates the angle in degrees of a line connecting two points relative to the horizontal.
    static func horizontalAngle(p1: CGPoint, p2: CGPoint) -> Double {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return atan2(dy, dx) * 180 / .pi
    }
    
    /// Checks if a point is within a normalized frame [0,1].
    static func isPointInFrame(_ point: CGPoint) -> Bool {
        return point.x >= 0 && point.x <= 1 && point.y >= 0 && point.y <= 1
    }
}
