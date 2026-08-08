import SwiftUI

struct ConsentView: View {
    var onAccept: () -> Void
    var onDecline: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.bottom, 6)

                    Text("Bilgilendirme ve Onay")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Devam etmeden önce lütfen okuyun.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.4))
                }
                .padding(.top, 60)
                .padding(.bottom, 36)
                .opacity(appeared ? 1 : 0)

                // Consent Cards
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        MinimalConsentCard(
                            icon: "camera.viewfinder",
                            title: "Sistem Hakkında",
                            text: "Bu sistem, fizyoterapistinizin değerlendirmesine yardımcı olmak amacıyla kamera üzerinden postür ve hareket analizi yapar. Sistem tıbbi bir teşhis koymaz."
                        )

                        MinimalConsentCard(
                            icon: "lock.shield",
                            title: "Görüntü İşleme",
                            text: "Kameradan alınan görüntüler anlık olarak cihaz üzerinde işlenir. Ham video kayıtları veya fotoğraflar sisteme kaydedilmez."
                        )

                        MinimalConsentCard(
                            icon: "server.rack",
                            title: "Veri Güvenliği",
                            text: "Hesaplanan eklem açıları ve test sonuçları klinik veri tabanında yerel ve güvenli bir şekilde saklanır."
                        )
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 140)
                }
                .opacity(appeared ? 1 : 0)
            }

            // Bottom Action Bar
            VStack {
                Spacer()

                VStack(spacing: 10) {
                    Button(action: onAccept) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                            Text("Okudum, Onaylıyorum")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(red: 0.31, green: 0.43, blue: 0.97))
                        )
                    }

                    Button(action: onDecline) {
                        Text("Onaylamıyorum")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.3))
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
                .background(
                    LinearGradient(
                        colors: [Color.black, Color.black.opacity(0)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .ignoresSafeArea()
                )
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }
}

struct MinimalConsentCard: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(Color(red: 0.31, green: 0.43, blue: 0.97))
                .frame(width: 24, height: 24)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text(text)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.5))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
