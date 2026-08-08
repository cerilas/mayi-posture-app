import SwiftUI
import SwiftData
import Combine

class ClinicianDataStore: ObservableObject {
    private var modelContext: ModelContext?
    
    @Published var patients: [PatientEntity] = []
    
    // Pagination states
    @Published var currentPage: Int = 1
    @Published var totalPages: Int = 1
    @Published var isFetching: Bool = false
    @Published var searchText: String = ""
    
    static let shared = ClinicianDataStore()
    
    private init() {}
    
    func setup(with context: ModelContext) {
        self.modelContext = context
        fetchPatients(page: 1, search: "")
    }
    
    func fetchPatients(page: Int = 1, search: String = "") {
        guard let context = modelContext else { return }
        
        // Prevent multiple simultaneous fetches
        guard !isFetching else { return }
        
        isFetching = true
        self.currentPage = page
        self.searchText = search
        
        Task {
            do {
                let response = try await PostureAPIService.shared.fetchPatients(pin: "0000", page: page, search: search)
                
                await MainActor.run {
                    self.totalPages = response.totalPages
                    
                    do {
                        // Eğer ilk sayfa ise veya arama değiştiyse lokal verileri temizle
                        if page == 1 {
                            try context.delete(model: PatientEntity.self)
                        }
                        
                        for rp in response.items {
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
                        
                        // Güncel datayı fetchle (sıralama için)
                        let descriptor = FetchDescriptor<PatientEntity>(sortBy: [SortDescriptor(\.firstName)])
                        self.patients = try context.fetch(descriptor)
                    } catch {
                        print("Sync save error: \(error)")
                    }
                    self.isFetching = false
                }
            } catch {
                print("Remote fetch failed: \(error)")
                await MainActor.run { self.isFetching = false }
            }
        }
    }
    
    func loadMoreIfNeeded(currentPatient: PatientEntity) {
        let thresholdIndex = patients.index(patients.endIndex, offsetBy: -5)
        if let idx = patients.firstIndex(where: { $0.id == currentPatient.id }), idx == thresholdIndex {
            if currentPage < totalPages && !isFetching {
                fetchPatients(page: currentPage + 1, search: searchText)
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
