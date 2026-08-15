import SwiftUI
import CoreMotion
import Combine

struct WelcomeView: View {
    var onStart: () -> Void
    var onStaffLogin: () -> Void

    @StateObject private var motionManager = MotionManager()
    @State private var appeared = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Background Image (Parallax efekti ile yarı transparan)
                Image("welcome_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .scaleEffect(1.1) // Hareket payı için biraz büyüttük
                    .offset(x: CGFloat(motionManager.roll * 50), y: CGFloat(motionManager.pitch * 50))
                    .opacity(0.2) // Yarı transparan
                    .clipped()
                    .allowsHitTesting(false)
                    .animation(.linear(duration: 0.1), value: motionManager.roll)
                    .animation(.linear(duration: 0.1), value: motionManager.pitch)

                VStack(spacing: 0) {
                    Spacer(minLength: 20)

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
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)

                        Text("MAHMUT YÜCEL FİZYOTERAPİ")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .tracking(3)
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                    Spacer(minLength: 20)

                    // Description
                    Text("Postür ve hareket analiziniz\nkamera destekli yapay zeka ile yapılacaktır.")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.white.opacity(0.45))
                        .lineSpacing(6)
                        .padding(.horizontal, 48)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)
                        .minimumScaleFactor(0.8)

                    Spacer(minLength: 20)

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
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 20 : 40)
                    .opacity(appeared ? 1 : 0)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .ignoresSafeArea(.all, edges: .all)
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

// MARK: - CoreMotion Parallax Manager
class MotionManager: ObservableObject {
    private var motionManager: CMMotionManager
    
    @Published var pitch: Double = 0.0
    @Published var roll: Double = 0.0
    
    init() {
        self.motionManager = CMMotionManager()
        self.motionManager.deviceMotionUpdateInterval = 1 / 60
        self.start()
    }
    
    func start() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
                guard let data = data, error == nil else { return }
                self?.pitch = data.attitude.pitch
                self?.roll = data.attitude.roll
            }
        }
    }
    
    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    deinit {
        stop()
    }
}
