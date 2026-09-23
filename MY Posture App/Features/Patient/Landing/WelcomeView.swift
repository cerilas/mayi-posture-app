import SwiftUI

struct WelcomeView: View {
    var onStart: () -> Void
    var onStaffLogin: () -> Void

    @State private var appeared = false
    private let accentColor = Color(red: 0.31, green: 0.43, blue: 0.97)

    var body: some View {
        ZStack {
            // Arka Plan
            Color(red: 0.04, green: 0.05, blue: 0.08)
                .ignoresSafeArea()

            // İnce gradient aurası
            VStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .offset(y: -100)
                Spacer()
            }
            .ignoresSafeArea()

            // Arka plan görseli (şeffaf ve sabit)
            Image("welcome_bg")
                .resizable()
                .scaledToFill()
                .opacity(0.12)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Ana İçerik
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 24)

                        // Logo ve Başlık Bölümü
                        VStack(spacing: 16) {
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 88, height: 88)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                                .shadow(color: accentColor.opacity(0.3), radius: 20, x: 0, y: 8)

                            VStack(spacing: 6) {
                                Text("MY POSTURE")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .tracking(3)
                                    .foregroundColor(.white)

                                Text("MAHMUT YÜCEL FİZYOTERAPİ")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .tracking(2.5)
                                    .foregroundColor(Color.white.opacity(0.5))
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)

                        Spacer(minLength: 24)

                        // Bilgilendirme Kartı
                        VStack(spacing: 14) {
                            HStack(spacing: 14) {
                                Image(systemName: "figure.stand")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(accentColor)
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(accentColor.opacity(0.15)))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Dijital Göz Muayenesi")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)

                                    Text("Omuz eğikliği, baş açısı ve omurga simetriniz kamerayla saniyeler içinde taranır.")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(Color.white.opacity(0.65))
                                        .lineSpacing(2)
                                }
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 28)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)

                        Spacer(minLength: 32)

                        // Aksiyon Butonları
                        VStack(spacing: 14) {
                            Button(action: onStart) {
                                HStack(spacing: 10) {
                                    Text("Değerlendirmeye Başla")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(accentColor)
                                )
                                .shadow(color: accentColor.opacity(0.4), radius: 15, x: 0, y: 8)
                            }

                            Button(action: onStaffLogin) {
                                HStack(spacing: 6) {
                                    Image(systemName: "lock.shield")
                                        .font(.system(size: 13, weight: .medium))
                                    Text("Personel / Terapist Girişi")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(Color.white.opacity(0.45))
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 24)
                        .opacity(appeared ? 1 : 0)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }
}

#Preview {
    WelcomeView(onStart: {}, onStaffLogin: {})
}
