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
enum AssessmentState {
    case idle
    case positioning
    case capturing(progress: Double)
    case completed(result: AssessmentTestResult)
    case failed(reason: String)
}
