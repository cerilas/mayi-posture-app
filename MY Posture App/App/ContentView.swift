import SwiftUI

struct ContentView: View {
    enum FlowState {
        case welcome
        case identification
        case consent
        case assessment
        case clinicianAuth
        case clinicianDashboard
        case debug
    }
    
    @Environment(\.modelContext) private var modelContext
    @State private var flowState: FlowState = .welcome
    @State private var patientCode: String = ""
    @State private var resolvedUserId: String?
    @State private var codeError: String?
    @State private var isLookingUp = false
    
    var body: some View {
        ZStack {
            switch flowState {
            case .welcome:
                WelcomeView(
                    onStart: { flowState = .identification },
                    onStaffLogin: { flowState = .clinicianAuth }
                )
                .transition(.move(edge: .trailing))
                
            case .identification:
                IdentificationView(
                    onIdentified: { code in
                        Task { await lookupCode(code) }
                    },
                    onCancel: { flowState = .welcome },
                    isLoading: isLookingUp,
                    errorMessage: codeError
                )
                .transition(.move(edge: .trailing))
                
            case .consent:
                ConsentView(
                    onAccept: { flowState = .assessment },
                    onDecline: { flowState = .welcome }
                )
                .transition(.move(edge: .trailing))
                
            case .assessment:
                AssessmentView(
                    onDismiss: { flowState = .welcome },
                    userId: resolvedUserId,
                    appointmentCode: patientCode
                )
                .transition(.opacity)
                
            case .clinicianAuth:
                ClinicianAuthView(
                    onAuthenticated: { flowState = .clinicianDashboard },
                    onCancel: { flowState = .welcome }
                )
                .transition(.move(edge: .bottom))
                
            case .clinicianDashboard:
                NavigationStack {
                    ClinicianDashboardView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Çıkış") { flowState = .welcome }
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Sistem Log") { flowState = .debug }
                            }
                        }
                }
                .transition(.move(edge: .bottom))
                
            case .debug:
                NavigationStack {
                    DebugPoseView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Geri") { flowState = .clinicianDashboard }
                            }
                        }
                }
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.spring(), value: flowState)
        .onAppear {
            ClinicianDataStore.shared.setup(with: modelContext)
        }
    }
    
    // MARK: - Code Lookup
    
    @MainActor
    private func lookupCode(_ code: String) async {
        isLookingUp = true
        codeError = nil
        
        do {
            let result = try await PostureAPIService.shared.lookupCode(code)
            patientCode = code
            resolvedUserId = result.userId
            isLookingUp = false
            flowState = .consent
        } catch let error as PostureAPIError {
            codeError = error.localizedDescription
            isLookingUp = false
        } catch {
            codeError = "Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin."
            isLookingUp = false
        }
    }
}

#Preview {
    ContentView()
}
