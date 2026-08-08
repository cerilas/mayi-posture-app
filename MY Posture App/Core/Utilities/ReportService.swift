import SwiftUI
import PDFKit
import CoreGraphics

class ReportService {
    static func generatePDF(for session: SessionEntity, patient: PatientEntity) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "MY Posture App",
            kCGPDFContextAuthor: "Mahmut Yücel Fizyoterapi",
            kCGPDFContextTitle: "Değerlendirme Raporu"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            let titleFont = UIFont.boldSystemFont(ofSize: 24.0)
            let headerFont = UIFont.boldSystemFont(ofSize: 18.0)
            let bodyFont = UIFont.systemFont(ofSize: 12.0)
            
            // Draw Title
            let title = "DEĞERLENDİRME RAPORU"
            let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont]
            title.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
            
            // Draw Patient Info
            var yOffset: CGFloat = 100
            let info = "Hasta: \(patient.fullName)\nTarih: \(session.date.formatted())\n"
            info.draw(at: CGPoint(x: 50, y: yOffset), withAttributes: [.font: bodyFont])
            
            yOffset += 60
            
            // Draw Results
            for result in session.results {
                let testTitle = result.testType.replacingOccurrences(of: "_", with: " ").uppercased()
                testTitle.draw(at: CGPoint(x: 50, y: yOffset), withAttributes: [.font: headerFont])
                yOffset += 25
                
                for m in result.measurements {
                    let text = "\(m.key): \(String(format: "%.1f%@", m.value, m.unit)) (Güven: \(Int(m.confidence * 100))%)"
                    text.draw(at: CGPoint(x: 70, y: yOffset), withAttributes: [.font: bodyFont])
                    yOffset += 20
                }
                yOffset += 20
            }
        }
        
        return data
    }
}
