import SwiftUI

struct ClinicianAuthView: View {
    @State private var pin: String = ""
    var onAuthenticated: () -> Void
    var onCancel: () -> Void
    
    private let correctPin = "0000" // Mock PIN for V1
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Personel Girişi")
                .font(.largeTitle)
                .bold()
            
            Text("Lütfen 4 haneli erişim kodunuzu giriniz.")
                .font(.title3)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(index < pin.count ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                }
            }
            .padding(.vertical, 20)
            
            // Simple Number Pad
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(80), spacing: 20), count: 3), spacing: 20) {
                ForEach(1...9, id: \.self) { num in
                    NumberButton(number: "\(num)", action: { addDigit("\(num)") })
                }
                
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                }
                
                NumberButton(number: "0", action: { addDigit("0") })
                
                Button(action: { if !pin.isEmpty { pin.removeLast() } }) {
                    Image(systemName: "delete.left")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding(50)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onChange(of: pin) { newValue in
            if newValue == correctPin {
                onAuthenticated()
            } else if newValue.count >= 4 {
                // Shake effect or reset
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    pin = ""
                }
            }
        }
    }
    
    private func addDigit(_ digit: String) {
        if pin.count < 4 {
            pin += digit
        }
    }
}

struct NumberButton: View {
    let number: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.title)
                .bold()
                .frame(width: 80, height: 80)
                .background(Circle().fill(Color(.secondarySystemBackground)))
                .foregroundColor(.primary)
        }
    }
}
