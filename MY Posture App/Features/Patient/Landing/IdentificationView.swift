import SwiftUI

struct IdentificationView: View {
    @State private var code: String = ""
    @FocusState private var isFocused: Bool
    var onIdentified: (String) -> Void
    var onCancel: () -> Void
    var isLoading: Bool = false
    var errorMessage: String? = nil

    @State private var appeared = false
    private let accentColor = Color(red: 0.31, green: 0.43, blue: 0.97)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 20)

                // Header
                VStack(spacing: 8) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.bottom, 6)

                    Text("Randevu Kodu")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Size verilen 6 haneli kodu giriniz.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.4))
                }
                .opacity(appeared ? 1 : 0)

                Spacer()

                // OTP Input
                ZStack {
                    TextField("", text: $code)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                        .opacity(0.01)
                        .frame(width: 1, height: 1)

                    HStack(spacing: 10) {
                        ForEach(0..<6, id: \.self) { index in
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.white.opacity(0.05))
                                    .frame(width: 46, height: 58)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(
                                                code.count == index ? accentColor : Color.white.opacity(0.12),
                                                lineWidth: code.count == index ? 1.5 : 1
                                            )
                                    )

                                if index < code.count {
                                    let charIndex = code.index(code.startIndex, offsetBy: index)
                                    Text(String(code[charIndex]))
                                        .font(.system(size: 26, weight: .semibold, design: .monospaced))
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
                .opacity(appeared ? 1 : 0)

                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color.red.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .transition(.opacity)
                }

                Spacer()
                Spacer()

                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("İptal")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.5))
                            .frame(width: 100, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )
                    }

                    Button(action: {
                        if code.count >= 4 { onIdentified(code) }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(code.count >= 4 ? accentColor : Color.white.opacity(0.12))
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                HStack(spacing: 8) {
                                    Text("Devam Et")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .disabled(code.count < 4 || isLoading)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 48)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
}
