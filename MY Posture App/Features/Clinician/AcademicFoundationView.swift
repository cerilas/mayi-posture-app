import SwiftUI

struct AcademicFoundationView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Akademik Dayanak")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("MY Posture App'in kullandığı ölçüm yöntemleri, 2D fotogrametri ve markerless (işaretsiz) pose estimation teknolojisinin geçerliliğini kanıtlayan güncel akademik çalışmalara dayanmaktadır.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
                
                // Makale 1
                ArticleCardView(
                    title: "1. Akıllı Telefon Kamerasıyla Baş-Boyun Postür Analizi",
                    subtitle: "Universitat Internacional de Catalunya (2023)",
                    content: "Bilgisayarlı görü tabanlı bir akıllı telefon uygulamasının baş postürü (Craniovertebral Açı - CVA) değerlendirmesindeki test-tekrar test güvenilirliği ICC=0,92 bulunmuş ve altın standart (Kinovea) ile r=0,94 düzeyinde korelasyon göstermiştir. Ölçüm hatası yalnızca 1,83°'dir.\n\nÖnemli Çıkarım: Telefon kamerasından hesaplanan tek bir postür parametresi klinik ön değerlendirmede anlamlı ve objektif veri üretebilir.",
                    icon: "iphone.smartbatterycase.gen2"
                )
                
                // Makale 2
                ArticleCardView(
                    title: "2. Yapay Zekâ ile Markerless Postür Analizi ve Radyografi",
                    subtitle: "Seoul Bumin Hospital (2025)",
                    content: "Yapay zekâ tabanlı (MORA Vu) yazılımın, radyografik (röntgen) ölçümlerle karşılaştırıldığı çalışmada; öne baş postürü ve dijital kalça-diz-ayak bileği açısı ölçümlerinin manuel işaretleme olmadan saniyeler içinde yapılabildiği kanıtlanmıştır. Güvenilirlik ICC=0,84 - 0,90 arasındadır.\n\nÖnemli Çıkarım: Özel kamera olmadan sadece mobil cihazlarla tarama yapılması teknik ve klinik olarak geçerli bir 'Screening Tool' (Tarama Aracı) sunar.",
                    icon: "camera.viewfinder"
                )
                
                // Makale 3
                ArticleCardView(
                    title: "3. 2D Kamera ile Fonksiyonel Hareket: Squat Analizi",
                    subtitle: "University of Virginia (2017)",
                    content: "2D video analizi ile alt ekstremite (kalça, diz, ayak bileği) kinematik ölçümlerinin 3D laboratuvar sistemleriyle karşılaştırıldığı çalışmada, sagittal (yandan) düzlemde diz açısı için yüksek korelasyon (r=0,86) ve sadece 0,74° fark bulunmuştur.\n\nÖnemli Çıkarım: 3D sistemlerin yüksek maliyetine karşılık, 2D mobil uygulamalar hızlı ve güvenilir bir klinik tarama alternatifidir.",
                    icon: "figure.walk"
                )
                
                // Makale 4
                ArticleCardView(
                    title: "4. Tek Bir Fotoğraf Statik Postürü Temsil Edebilir mi?",
                    subtitle: "Universidade Federal do Rio Grande do Sul (2019)",
                    content: "Fotogrametri ile 30 saniyelik bir süreçte çekilen farklı kareler incelenmiş ve hata payının %5'in altında (ICC > 0,91) olduğu görülmüştür.\n\nÖnemli Çıkarım: Bireyin kameranın önüne geçip doğru pozisyonda saniyeler içinde alınan tek bir görüntüsü (veya en stabil karesi) statik postürü güvenilir şekilde temsil eder.",
                    icon: "photo.on.rectangle"
                )
                
                // Makale 5
                ArticleCardView(
                    title: "5. Uzaktan Eklem Hareket Açıklığı (ROM) Meta-Analizi",
                    subtitle: "Journal of Shoulder and Elbow Surgery (2026)",
                    content: "26 farklı araştırmanın incelendiği meta-analizde, akıllı telefon ve yapay zeka tabanlı ölçümlerin referans yöntemlere göre ortalama sadece 2,63° fark yarattığı saptanmıştır. Makine öğrenmesi kullanan sistemlerde ICC=0,92–0,97 gibi mükemmel güvenilirlik sonuçları vardır.\n\nÖnemli Çıkarım: Fiziksel temas olmadan, hastanın dijital yönergelerle uzaktan eklem açılarını ölçmesi, tedavi takibi (trend monitoring) için son derece uygundur.",
                    icon: "angle"
                )
                
                // Sonuç / Değer Önerisi
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        Text("Sonuç ve Klinik Konumlandırma")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    Text("Bu beş bilimsel makalenin ortak sonucuna göre; uygulamanız bir 'otomatik teşhis' aracı değil, fizyoterapisti destekleyen objektif bir **AI Destekli Fizyoterapi Ön Değerlendirme (Screening)** ve **Uzaktan Takip (Longitudinal Monitoring)** aracıdır. Mevcut literatür, 2D kamera ve markerless yapay zekanın bu amaçlar doğrultusunda düşük maliyetli, noninvaziv ve klinik açıdan oldukça güvenilir olduğunu kanıtlamaktadır.")
                        .font(.callout)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding(.top, 10)
                
            }
            .padding()
        }
        .navigationTitle("Akademik Literatür")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ArticleCardView: View {
    let title: String
    let subtitle: String
    let content: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(.primary.opacity(0.8))
                .lineSpacing(4)
                .padding(.leading, 38)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

#Preview {
    NavigationView {
        AcademicFoundationView()
    }
}
