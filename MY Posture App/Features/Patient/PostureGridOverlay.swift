import SwiftUI

/// Klinik Postür Analiz Posteri Izgarası ve Merkezi Çekül Hattı (Plumb Line)
struct PostureGridOverlay: View {
    var isAligned: Bool = false

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let w = size.width
                let h = size.height
                let centerX = w / 2
                let centerY = h / 2
                let gridSize: CGFloat = 36.0

                // 1. Yarı Görünür Kare Izgara Çizgileri (Grid Lines)
                var gridPath = Path()

                // Dikey ızgara çizgileri (merkezden sağa ve sola)
                var x = centerX - gridSize
                while x > 0 {
                    gridPath.move(to: CGPoint(x: x, y: 0))
                    gridPath.addLine(to: CGPoint(x: x, y: h))
                    x -= gridSize
                }
                x = centerX + gridSize
                while x < w {
                    gridPath.move(to: CGPoint(x: x, y: 0))
                    gridPath.addLine(to: CGPoint(x: x, y: h))
                    x += gridSize
                }

                // Yatay ızgara çizgileri (merkezden yukarı ve aşağı)
                var y = centerY - gridSize
                while y > 0 {
                    gridPath.move(to: CGPoint(x: 0, y: y))
                    gridPath.addLine(to: CGPoint(x: w, y: y))
                    y -= gridSize
                }
                y = centerY + gridSize
                while y < h {
                    gridPath.move(to: CGPoint(x: 0, y: y))
                    gridPath.addLine(to: CGPoint(x: w, y: y))
                    y += gridSize
                }

                // Kareleri çok hafif yarı saydam çiz
                context.stroke(
                    gridPath,
                    with: .color(Color.white.opacity(0.09)),
                    style: StrokeStyle(lineWidth: 0.75)
                )

                // 2. Çekül Hattı Rengi (Hizalanınca yeşil, normalde açık mavi/cyan)
                let plumbColor: Color = isAligned ? Color.green : Color(red: 0.31, green: 0.65, blue: 0.97)

                // 3. Merkezi Yatay Referans Çizgisi
                var hCenter = Path()
                hCenter.move(to: CGPoint(x: 0, y: centerY))
                hCenter.addLine(to: CGPoint(x: w, y: centerY))
                context.stroke(
                    hCenter,
                    with: .color(plumbColor.opacity(0.45)),
                    style: StrokeStyle(lineWidth: 1.2, dash: [6, 4])
                )

                // 4. Merkezi Dikey Çekül Hattı (Vertical Gravity / Plumb Line)
                var vCenter = Path()
                vCenter.move(to: CGPoint(x: centerX, y: 0))
                vCenter.addLine(to: CGPoint(x: centerX, y: h))
                context.stroke(
                    vCenter,
                    with: .color(plumbColor.opacity(0.8)),
                    style: StrokeStyle(lineWidth: 1.8)
                )

                // 5. Çekül Hattı Üzerindeki Cetvel / Kalibrasyon Çentikleri (Tick Marks)
                var ticks = Path()
                var tickY: CGFloat = 0
                while tickY < h {
                    ticks.move(to: CGPoint(x: centerX - 5, y: tickY))
                    ticks.addLine(to: CGPoint(x: centerX + 5, y: tickY))
                    tickY += gridSize
                }
                context.stroke(
                    ticks,
                    with: .color(plumbColor.opacity(0.55)),
                    style: StrokeStyle(lineWidth: 1.0)
                )

                // 6. Merkez Hedef Dairesi
                let centerRect = CGRect(x: centerX - 12, y: centerY - 12, width: 24, height: 24)
                context.stroke(
                    Path(ellipseIn: centerRect),
                    with: .color(plumbColor.opacity(0.7)),
                    style: StrokeStyle(lineWidth: 1.2)
                )
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

#Preview {
    ZStack {
        Color.black
        PostureGridOverlay(isAligned: false)
    }
}
