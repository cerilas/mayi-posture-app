import Foundation

/// A utility to track phases of a cyclical movement (like a squat).
class MovementStateMachine {
    enum State: String {
        case standing
        case descending
        case bottom
        case ascending
    }
    
    private(set) var currentState: State = .standing
    private(set) var repetitionCount: Int = 0
    
    private let thresholdDescending: Double
    private let thresholdBottom: Double
    private let thresholdStanding: Double
    
    /// Initialize with angular thresholds (e.g., knee angle)
    init(descending: Double, bottom: Double, standing: Double) {
        self.thresholdDescending = descending
        self.thresholdBottom = bottom
        self.thresholdStanding = standing
    }
    
    func update(currentValue: Double) -> (State, Bool) {
        let previousState = currentState
        var repCompleted = false
        
        switch currentState {
        case .standing:
            if currentValue < thresholdDescending {
                currentState = .descending
            }
        case .descending:
            if currentValue < thresholdBottom {
                currentState = .bottom
            } else if currentValue > thresholdStanding {
                currentState = .standing
            }
        case .bottom:
            if currentValue > thresholdBottom + 10 { // Add some hysteresis
                currentState = .ascending
            }
        case .ascending:
            if currentValue > thresholdStanding {
                currentState = .standing
                repetitionCount += 1
                repCompleted = true
            }
        }
        
        return (currentState, repCompleted)
    }
    
    func reset() {
        currentState = .standing
        repetitionCount = 0
    }
}
