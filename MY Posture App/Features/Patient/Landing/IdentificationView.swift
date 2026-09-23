import SwiftUI

struct IdentificationView: View {
    @State private var code: String = ""
    @FocusState private var isFocused: Bool
    var onIdentified: (String) -> Void
    var onSkip: () -> Void = {}
    var onCancel: () -> Void
    var isLoading: Bool = false
    var errorMessage: String? = nil

    @State private var appeared = false
    private let accentColor = Color(red: 0.31, green: 0.43, blue: 0.97)

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.05, blue: 0.08)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Üst Bar (Geri Butonu)
                HStack {
                    Button(action: onCancel) {
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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Başlık ve Açıklama
                        VStack(spacing: 12) {
                            Image(systemName: "number.square.fill")
                                .font(.system(size: 40))
                                .foregroundColor(accentColor)
                                .padding(.top, 20)

                            Text("Randevu Kodu")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("Fizyoterapistinizin verdiği 6 haneli kodu giriniz.")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.55))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        // OTP Giriş Kutuları
                        ZStack {
                            TextField("", text: $code)
                                .keyboardType(.asciiCapable)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .focused($isFocused)
                                .opacity(0.01)
                                .frame(width: 1, height: 1)

                            HStack(spacing: 8) {
                                ForEach(0..<6, id: \.self) { index in
                                    let isCurrent = code.count == index
                                    let isFilled = index < code.count
                                    
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.white.opacity(0.06))
                                            .frame(width: 44, height: 56)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(
                                                        isCurrent ? accentColor : (isFilled ? accentColor.opacity(0.4) : Color.white.opacity(0.12)),
                                                        lineWidth: isCurrent ? 2 : 1
                                                    )
                                            )

                                        if isFilled {
                                            let charIndex = code.index(code.startIndex, offsetBy: index)
                                            Text(String(code[charIndex]))
                                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { isFocused = true }
                        .onChange(of: code) { _, newValue in
                            if newValue.count > 6 {
                                code = String(newValue.prefix(6))
                            }
                            if newValue.count == 6 {
                                isFocused = false
                            }
                        }

                        // Hata Mesajı
                        if let error = errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 13))
                                Text(error)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(Color.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .transition(.opacity)
                        }

                        // Aksiyon Butonları
                        VStack(spacing: 12) {
                            Button(action: {
                                if code.count >= 4 { onIdentified(code) }
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(code.count >= 4 ? accentColor : Color.white.opacity(0.12))
                                    
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        HStack(spacing: 8) {
                                            Text("Devam Et")
                                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                            Image(systemName: "arrow.right")
                                                .font(.system(size: 14, weight: .bold))
                                        }
                                        .foregroundColor(code.count >= 4 ? .white : Color.white.opacity(0.4))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                            }
                            .disabled(code.count < 4 || isLoading)

                            // Kodu olmayan kullanıcı için hızlı başlangıç
                            Button(action: onSkip) {
                                HStack(spacing: 6) {
                                    Text("Randevu Kodum Yok / Hızlı Başla")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                    Image(systemName: "chevron.forward")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundColor(Color.white.opacity(0.45))
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, 12)
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isFocused = true
            }
        }
    }
}

#Preview {
    IdentificationView(
        onIdentified: { _ in },
        onSkip: {},
        onCancel: {}
    )
}
