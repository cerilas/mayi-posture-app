import SwiftUI

struct SessionDetailView: View {
    let session: SessionEntity
    
    var body: some View {
        List {
            Section("Oturum Detayları") {
                LabeledContent("Tarih", value: session.date.formatted(date: .long, time: .shortened))
                LabeledContent("Durum", value: session.status.capitalized)
            }
            
            ForEach(session.results) { result in
                Section(header: Text(result.testType.replacingOccurrences(of: "_", with: " ").capitalized)) {
                    ForEach(result.measurements.sorted(by: { $0.key < $1.key }), id: \.key) { measurement in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(formatKey(measurement.key))
                                Spacer()
                                Text(String(format: "%.1f%@", measurement.value, measurement.unit))
                                    .bold()
                                    .foregroundColor(colorForValue(measurement.value))
                            }
                            
                            HStack {
                                Text("Güven Aralığı: \(Int(measurement.confidence * 100))%")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(result.quality.uppercased())
                                    .font(.caption2)
                                    .padding(.horizontal, 4)
                                    .background(colorForQuality(result.quality).opacity(0.1))
                                    .foregroundColor(colorForQuality(result.quality))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Değerlendirme Özeti")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let patient = session.patient {
                    ShareLink(item: generatePDF(patient: patient), preview: SharePreview("Rapor", image: Image(systemName: "doc.pdf"))) {
                        Label("Paylaş", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }
    
    private func generatePDF(patient: PatientEntity) -> URL {
        let data = ReportService.generatePDF(for: session, patient: patient)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Rapor.pdf")
        try? data.write(to: url)
        return url
    }
    
    private func formatKey(_ key: String) -> String {
        key.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .capitalized
    }
    
    private func colorForQuality(_ quality: String) -> Color {
        switch quality.lowercased() {
        case "high": return .green
        case "acceptable": return .blue
        case "low": return .orange
        case "invalid": return .red
        default: return .gray
        }
    }
    
    private func colorForValue(_ value: Double) -> Color {
        abs(value) > 5.0 ? .red : .primary
    }
}
