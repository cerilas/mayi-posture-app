import SwiftUI

struct ConsentView: View {
    var onAccept: () -> Void
    var onDecline: () -> Void

    @State private var appeared = false
    private let accentColor = Color(red: 0.31, green: 0.43, blue: 0.97)

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.05, blue: 0.08)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Üst Bar
                HStack {
                    Button(action: onDecline) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Geri")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Kaydırılabilir Kartlar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Başlık
                        VStack(spacing: 8) {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 36))
                                .foregroundColor(accentColor)
                                .padding(.top, 12)

                            Text("Bilgilendirme ve Onay")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("Devam etmeden önce lütfen okuyunuz.")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.55))
                        }
                        .padding(.bottom, 8)

                        // Kart 1
                        ModernConsentCard(
                            icon: "camera.viewfinder",
                            title: "Sistem Hakkında",
                            text: "Bu uygulama, fizyoterapistinizin ön değerlendirmesine yardımcı olmak amacıyla kamera üzerinden postür taraması yapar. Kesin tıbbi bir teşhis koymaz."
                        )

                        // Kart 2
                        ModernConsentCard(
                            icon: "lock.shield.fill",
                            title: "Cihaz Üzerinde İşleme",
                            text: "Kameradan alınan görüntüler gerçek zamanlı olarak cihazınızda işlenir. Ham video kayıtları sunuculara yüklenmez."
                        )

                        // Kart 3
                        ModernConsentCard(
                            icon: "server.rack",
                            title: "Klinik Veri Güvenliği",
                            text: "Hesaplanan duruş açıları ve test özetiniz fizyoterapist seans takibi amacıyla güvenli olarak saklanır."
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                // Sabit Alt Aksiyon Çubuğu
                VStack(spacing: 12) {
                    Button(action: onAccept) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                            Text("Okudum, Onaylıyorum")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(accentColor)
                        )
                        .shadow(color: accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
                    }

                    Button(action: onDecline) {
                        Text("Vazgeç")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    Color(red: 0.04, green: 0.05, blue: 0.08)
                        .overlay(
                            Rectangle()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 1),
                            alignment: .top
                        )
                )
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }
}

struct ModernConsentCard: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(red: 0.31, green: 0.43, blue: 0.97))
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color(red: 0.31, green: 0.43, blue: 0.97).opacity(0.12)))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(text)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.6))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ConsentView(onAccept: {}, onDecline: {})
}
