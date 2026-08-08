import SwiftUI

/// A modern, minimal success card shown after the entire assessment completes.
struct AssessmentResultSummaryView: View {
    let result: AssessmentTestResult // Unused now, but kept for compatibility
    var onDismiss: () -> Void

    private let accentColor = Color(red: 0.31, green: 0.43, blue: 0.97)

    var body: some View {
        VStack(spacing: 0) {
            // Header Icon
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44, weight: .regular))
                        .foregroundColor(.green)
                }
                .padding(.top, 40)

                Text("Analiz Tamamlandı")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)

                Text("Tüm testleri başarıyla bitirdiniz. Sonucunuz fizyoterapistinize güvenli bir şekilde iletilmiştir.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 30)
            }

            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.horizontal, 24)

            // Dismiss button
            Button(action: onDismiss) {
                Text("Ana Ekrana Dön")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(accentColor)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .frame(width: 340)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(white: 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 30, x: 0, y: 15)
    }
}
