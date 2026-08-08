import Foundation

/// Protocol for all assessment modules (e.g., FrontPosture, Squat, etc.)
protocol AssessmentModule {
    var id: String { get }
    var title: String { get }
    var instructions: [String] { get }
    
    func processPose(_ pose: BodyPose)
    func finish() -> AssessmentTestResult
    func reset()
}

/// States for an assessment module.
enum AssessmentState: Equatable {
    case idle
    case instruction
    case positioning
    case capturing(progress: Double)
    case completed(result: AssessmentTestResult)
    case failed(reason: String)
    
    // Equatable desteği (gerekirse enum için otomatik gelir ama Double içeren capturing için eklemek gerekebilir)
    static func == (lhs: AssessmentState, rhs: AssessmentState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.instruction, .instruction), (.positioning, .positioning): return true
        case (.capturing(let l), .capturing(let r)): return l == r
        case (.completed(let l), .completed(let r)): return l.type == r.type
        case (.failed(let l), .failed(let r)): return l == r
        default: return false
        }
    }
}
