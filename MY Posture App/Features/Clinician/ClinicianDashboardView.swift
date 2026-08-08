import SwiftUI

struct ClinicianDashboardView: View {
    @StateObject private var dataStore = ClinicianDataStore.shared
    @State private var searchText = ""
    
    @AppStorage("enable_front_posture") private var enableFrontPosture = true
    @AppStorage("enable_side_posture") private var enableSidePosture = true
    @AppStorage("enable_shoulder_flexion") private var enableShoulderFlexion = true
    @AppStorage("enable_shoulder_abduction") private var enableShoulderAbduction = true
    @AppStorage("enable_squat") private var enableSquat = true
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Aktif Test Modülleri")) {
                    Toggle("Ön Postür Analizi", isOn: $enableFrontPosture)
                        .tint(.blue)
                    Toggle("Yan Postür Analizi", isOn: $enableSidePosture)
                        .tint(.blue)
                    Toggle("Omuz Fleksiyonu", isOn: $enableShoulderFlexion)
                        .tint(.blue)
                    Toggle("Omuz Abdüksiyonu", isOn: $enableShoulderAbduction)
                        .tint(.blue)
                    Toggle("Squat Analizi (5 Tekrar)", isOn: $enableSquat)
                        .tint(.blue)
                }
                
                Section(header: Text("Bilgi & Kaynaklar")) {
                    NavigationLink(destination: AcademicFoundationView()) {
                        HStack {
                            Image(systemName: "books.vertical.fill")
                                .foregroundColor(.blue)
                            Text("Akademik Dayanak")
                        }
                    }
                }
                
                Section(header: Text("Kayıtlı Hastalar")) {
                    ForEach(dataStore.patients) { patient in
                        NavigationLink(destination: PatientDetailView(patient: patient)) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(patient.fullName)
                                    .font(.headline)
                                if let lastSession = patient.sessions.sorted(by: { $0.date > $1.date }).first {
                                    Text("Son Değerlendirme: \(lastSession.date.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 5)
                            .onAppear {
                                dataStore.loadMoreIfNeeded(currentPatient: patient)
                            }
                        }
                    }
                    
                    if dataStore.isFetching {
                        HStack {
                            Spacer()
                            ProgressView("Yükleniyor...")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Yönetim Paneli")
            .searchable(text: $searchText, prompt: "Hasta Ara")
            .onChange(of: searchText) { newValue in
                // Gerçek sunucu araması (Server-side search)
                // Basit bir debounce simülasyonu için küçük bir bekleme veya doğrudan çağrı yapılabilir.
                // Şimdilik doğrudan tetikliyoruz.
                dataStore.fetchPatients(page: 1, search: newValue)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
        }
    }
}

struct PatientDetailView: View {
    let patient: PatientEntity
    @StateObject private var dataStore = ClinicianDataStore.shared
    
    var body: some View {
        List {
            Section("Kişisel Bilgiler") {
                LabeledContent("Doğum Yılı", value: "\(patient.birthYear)")
                LabeledContent("ID", value: patient.id.uuidString.prefix(8))
            }
            
            Section("Değerlendirme Geçmişi") {
                let sessions = patient.sessions.sorted { $0.date > $1.date }
                if sessions.isEmpty {
                    Text("Henüz değerlendirme bulunamadı.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(sessions) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                Text(session.date.formatted(date: .long, time: .shortened))
                                Spacer()
                                Text("\(session.results.count) Test")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            if patient.sessions.count >= 2 {
                Section {
                    NavigationLink(destination: ComparisonView(patient: patient)) {
                        Label("Gelişim Karşılaştır", systemImage: "arrow.left.and.right.circle.fill")
                            .foregroundColor(.blue)
                            .bold()
                    }
                }
            }
        }
        .navigationTitle(patient.fullName)
    }
}
