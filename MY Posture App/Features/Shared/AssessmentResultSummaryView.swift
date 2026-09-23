import SwiftUI

/// Fizyoterapist Göz Muayenesi Sonuç Kartı
struct AssessmentResultSummaryView: View {
    var result: AssessmentTestResult? = nil
    var summary: ClinicalPostureSummary = ClinicalPostureSummary()
    var onDismiss: () -> Void

    private let accentColor = Color(red: 0.31, green: 0.43, blue: 0.97)

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.green)
                }
                .padding(.top, 28)

                Text("Postür Muayenesi Tamamlandı")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Fizyoterapist göz muayenesi kriterlerine göre duruşunuz analiz edildi.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)

            Divider()
                .background(Color.white.opacity(0.12))
                .padding(.horizontal, 20)

            // Bulgular Listesi
            VStack(spacing: 12) {
                // 1. Omuz Seviyesi
                findingRow(
                    icon: "figure.stand",
                    title: "Omuz Seviyesi",
                    value: summary.shoulderStatus,
                    statusColor: summary.shoulderColor
                )

                // 2. Baş Duruşu
                findingRow(
                    icon: "brain.head.profile",
                    title: "Baş Eğikliği",
                    value: summary.headStatus,
                    statusColor: summary.headTilt < 2.0 ? .green : .orange
                )

                // 3. İleri Baş Duruşu (Yan Bakış)
                if summary.forwardHeadAngle > 0 {
                    findingRow(
                        icon: "person.crop.rectangle.stack",
                        title: "İleri Baş (FHP)",
                        value: summary.forwardHeadStatus,
                        statusColor: summary.forwardHeadColor
                    )
                }

                // 4. Gövde Simetrisi (Eğer kalça algılandıysa)
                if let trunk = summary.trunkLean {
                    findingRow(
                        icon: "arrow.up.and.down.and.sparkles",
                        title: "Gövde Dikliği",
                        value: trunk < 2.5 ? "Omurga Dengeli" : String(format: "%.1f° Gövde Eğimi", trunk),
                        statusColor: trunk < 2.5 ? .green : .orange
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)

            Divider()
                .background(Color.white.opacity(0.12))
                .padding(.horizontal, 20)

            // Kapat Butonu
            Button(action: onDismiss) {
                Text("Tamamla ve Ana Ekrana Dön")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(accentColor)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .frame(width: 340)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(white: 0.14))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.45), radius: 30, x: 0, y: 15)
    }

    private func findingRow(icon: String, title: String, value: String, statusColor: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(statusColor)
                .frame(width: 28, height: 28)
                .background(Circle().fill(statusColor.opacity(0.15)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }
}
