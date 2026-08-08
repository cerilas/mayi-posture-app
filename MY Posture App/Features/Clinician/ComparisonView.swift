import SwiftUI

struct ComparisonView: View {
    let patient: PatientEntity
    @StateObject private var dataStore = ClinicianDataStore.shared
    
    var body: some View {
        let sessions = patient.sessions.sorted { $0.date > $1.date }
        
        if sessions.count < 2 {
            Text("Karşılaştırma için en az iki değerlendirme gereklidir.")
        } else {
            let current = sessions[0]
            let previous = sessions[1]
            
            List {
                Section("Karşılaştırma Tarihleri") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Önceki")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(previous.date.formatted(date: .abbreviated, time: .omitted))
                                .bold()
                        }
                        Spacer()
                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Güncel")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(current.date.formatted(date: .abbreviated, time: .omitted))
                                .bold()
                        }
                    }
                    .padding(.vertical, 10)
                }
                
                let commonTestTypes = Set(current.results.map { $0.testType }).intersection(previous.results.map { $0.testType })
                
                ForEach(Array(commonTestTypes).sorted(), id: \.self) { type in
                    let currentResult = current.results.first(where: { $0.testType == type })!
                    let previousResult = previous.results.first(where: { $0.testType == type })!
                    
                    Section(header: Text(type.replacingOccurrences(of: "_", with: " ").capitalized)) {
                        let currentMetrics = Dictionary(uniqueKeysWithValues: currentResult.measurements.map { ($0.key, $0) })
                        let previousMetrics = Dictionary(uniqueKeysWithValues: previousResult.measurements.map { ($0.key, $0) })
                        let commonMetricKeys = Set(currentMetrics.keys).intersection(previousMetrics.keys)
                        
                        ForEach(Array(commonMetricKeys).sorted(), id: \.self) { metricKey in
                            let curVal = currentMetrics[metricKey]!
                            let prevVal = previousMetrics[metricKey]!
                            let diff = curVal.value - prevVal.value
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text(formatKey(metricKey))
                                        .font(.subheadline)
                                    Spacer()
                                    diffIndicator(diff: diff)
                                }
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(String(format: "%.1f%@", prevVal.value, prevVal.unit))
                                            .font(.title3)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text(String(format: "%.1f%@", curVal.value, curVal.unit))
                                            .font(.title3)
                                            .bold()
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
            .navigationTitle("Gelişim Analizi")
        }
    }
    
    private func formatKey(_ key: String) -> String {
        key.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .capitalized
    }
    
    @ViewBuilder
    private func diffIndicator(diff: Double) -> some View {
        HStack(spacing: 4) {
            Image(systemName: diff >= 0 ? "arrow.up.right" : "arrow.down.right")
            Text(String(format: "%.1f", abs(diff)))
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(diffColor(diff).opacity(0.1))
        .foregroundColor(diffColor(diff))
        .cornerRadius(8)
    }
    
    private func diffColor(_ diff: Double) -> Color {
        abs(diff) < 0.5 ? .gray : (diff > 0 ? .orange : .green)
    }
}
