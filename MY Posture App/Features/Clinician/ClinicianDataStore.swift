import SwiftUI
import SwiftData
import Combine

class ClinicianDataStore: ObservableObject {
    private var modelContext: ModelContext?
    
    @Published var patients: [PatientEntity] = []
    
    static let shared = ClinicianDataStore()
    
    private init() {}
    
    func setup(with context: ModelContext) {
        self.modelContext = context
        fetchPatients()
    }
    
    func fetchPatients() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<PatientEntity>(sortBy: [SortDescriptor(\.firstName)])
        do {
            patients = try context.fetch(descriptor)
        } catch {
            print("Fetch error: \(error)")
        }
        
        Task {
            do {
                let remotePatients = try await PostureAPIService.shared.fetchPatients(pin: "0000")
                await MainActor.run {
                    do {
                        try context.delete(model: PatientEntity.self)
                        
                        for rp in remotePatients {
                            let pId = UUID(uuidString: rp.id) ?? UUID()
                            let p = PatientEntity(id: pId, firstName: rp.name, lastName: "", birthYear: rp.birthYear)
                            
                            if let lastSessionStr = rp.lastSessionDate {
                                let formatter = ISO8601DateFormatter()
                                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                                if let date = formatter.date(from: lastSessionStr) ?? ISO8601DateFormatter().date(from: lastSessionStr) {
                                    let session = SessionEntity(date: date, status: "completed")
                                    p.sessions.append(session)
                                }
                            }
                            context.insert(p)
                        }
                        self.patients = try context.fetch(descriptor)
                    } catch {
                        print("Sync save error: \(error)")
                    }
                }
            } catch {
                print("Remote fetch failed: \(error)")
            }
        }
    }
    
    func addPatient(_ patient: PatientEntity) {
        modelContext?.insert(patient)
        fetchPatients()
    }
    
    func saveSession(_ session: SessionEntity, for patient: PatientEntity) {
        session.patient = patient
        modelContext?.insert(session)
        fetchPatients()
    }
}
