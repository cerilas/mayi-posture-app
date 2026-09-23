import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("record_assessment_video") private var recordAssessmentVideo: Bool = true
    
    @AppStorage("enable_front_posture") private var enableFrontPosture = true
    @AppStorage("enable_side_posture") private var enableSidePosture = true
    @AppStorage("enable_shoulder_flexion") private var enableShoulderFlexion = true
    @AppStorage("enable_shoulder_abduction") private var enableShoulderAbduction = true
    @AppStorage("enable_squat") private var enableSquat = true
    
    private let accentColor = Color(red: 0.31, green: 0.43, blue: 0.97)
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Video Kaydı Ayarı
                Section {
                    Toggle(isOn: $recordAssessmentVideo) {
                        HStack(spacing: 12) {
                            Image(systemName: "video.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.red))
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Değerlendirme Video Kaydı")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("Her randevu değerlendirmesinde otomatik başlar")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .tint(accentColor)
                } header: {
                    Text("Otomatik Video Kaydı")
                } footer: {
                    Text("Bu ayar açık olduğunda, hasta değerlendirmesi boyunca kamera kesintisiz video kaydı alır. Pozisyonlar arasında kesinti olmaz. Randevu tamamlandığında video yüksek verimlilikle sıkıştırılıp sunucuya yüklenir ve web raporuna işlenir.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                // MARK: - Test Modülleri
                Section {
                    Toggle("Ön Postür Analizi", isOn: $enableFrontPosture)
                        .tint(accentColor)
                    Toggle("Yan Postür Analizi", isOn: $enableSidePosture)
                        .tint(accentColor)
                    Toggle("Omuz Fleksiyonu", isOn: $enableShoulderFlexion)
                        .tint(accentColor)
                    Toggle("Omuz Abdüksiyonu", isOn: $enableShoulderAbduction)
                        .tint(accentColor)
                    Toggle("Squat Analizi (5 Tekrar)", isOn: $enableSquat)
                        .tint(accentColor)
                } header: {
                    Text("Aktif Test Modülleri")
                } footer: {
                    Text("Seçilen modüller sırayla değerlendirme akışına dahil edilir.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                // MARK: - Bilgi & Sürüm
                Section {
                    HStack {
                        Text("Uygulama")
                        Spacer()
                        Text("MY Posture App")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Geliştirici")
                        Spacer()
                        Text("Mahmut Yücel Fizyoterapi")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Sürüm")
                        Spacer()
                        Text("1.2 (Build 2026)")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Sistem")
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(accentColor)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
