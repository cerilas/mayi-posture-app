import SwiftUI
import PDFKit

struct PDFKitView: UIViewRepresentable {
    let pdfData: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        if let document = PDFDocument(data: pdfData) {
            pdfView.document = document
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document == nil {
            if let document = PDFDocument(data: pdfData) {
                uiView.document = document
            }
        }
    }
}

struct PDFViewer: View {
    let assetName: String
    let title: String
    
    @State private var pdfData: Data? = nil
    
    var body: some View {
        Group {
            if let data = pdfData {
                PDFKitView(pdfData: data)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow)
                    Text("PDF dosyası bulunamadı veya yüklenemedi.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadPDF()
        }
    }
    
    private func loadPDF() {
        if let asset = NSDataAsset(name: assetName) {
            self.pdfData = asset.data
        } else {
            print("Failed to load PDF asset: \(assetName)")
        }
    }
}
