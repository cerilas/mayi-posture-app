import SwiftUI

struct WelcomeView: View {
    var onStart: () -> Void
    var onStaffLogin: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Brand
                VStack(spacing: 12) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.white.opacity(0.1), radius: 10, x: 0, y: 0)

                    Text("MY POSTURE")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .tracking(4)
                        .foregroundColor(.white)

                    Text("MAHMUT YÜCEL FİZYOTERAPİ")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .tracking(3)
                        .foregroundColor(Color.white.opacity(0.4))
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

                Spacer()

                // Description
                Text("Postür ve hareket analiziniz\nkamera destekli yapay zeka ile yapılacaktır.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.white.opacity(0.45))
                    .lineSpacing(6)
                    .padding(.horizontal, 48)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)

                Spacer()

                // CTA Button
                Button(action: onStart) {
                    HStack(spacing: 10) {
                        Text("Değerlendirmeye Başla")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(red: 0.31, green: 0.43, blue: 0.97))
                    )
                }
                .padding(.horizontal, 40)
                .opacity(appeared ? 1 : 0)

                // Staff Login
                Button(action: onStaffLogin) {
                    Text("Personel Girişi")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.3))
                }
                .padding(.top, 18)
                .padding(.bottom, 48)
                .opacity(appeared ? 1 : 0)
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
