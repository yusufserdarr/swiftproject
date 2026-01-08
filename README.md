# Suİzim - Su Ayak İzi ve Baraj Doluluk Takibi

**Suİzim**, günlük su ayak izinizi hesaplamanıza ve Türkiye'nin büyük şehirlerindeki baraj doluluk oranlarını canlı olarak takip etmenize yardımcı olan bir iOS uygulamasıdır. Hem doğrudan su tüketiminizi (musluk, duş vb.) hem de sanal su tüketiminizi (yediğiniz gıdalar, kıyafetler vb.) takip ederek su tasarrufu bilinci oluşturmayı hedefler.

## 🌟 Özellikler

*   **💧 Su Ayak İzi Hesaplama:**
    *   **Ev İçi Kullanım:** Duş, bulaşık, çamaşır gibi günlük aktivitelerinizi kaydedin.
    *   **Sanal Su:** Kahve, hamburger, tişört gibi tüketimlerinizin "görünmeyen" su maliyetini öğrenin.
*   **baraj Baraj Doluluk Oranları:**
    *   İstanbul (İSKİ), Ankara (ASKİ), İzmir (İZSU) ve Bursa (BUSKİ) verilerine anlık erişim.
    *   Şehir geneli ortalamaları ve baraj bazlı detaylı doluluk grafikleri.
*   **📱 Widget Desteği:**
    *   iOS Ana Ekran widget'ı ile uygulamayı açmadan baraj doluluk oranlarını ve günlük su izinizi görün.
*   **💡 Akıllı Öneriler:**
    *   Günlük su kullanımınıza göre tasarruf önerileri ve "Günün İpucu" özelliği.
*   **📊 İstatistikler ve Takip:**
    *   SwiftData ile verileriniz cihazınızda güvenle saklanır.
    *   Geçmişe dönük kullanım takibi.

## 🛠 Kullanılan Teknolojiler

*   **Swift & SwiftUI:** Modern ve akıcı kullanıcı arayüzü.
*   **SwiftData:** Yerel veri saklama ve yönetimi.
*   **WidgetKit:** iOS Ana Ekran widget entegrasyonu.
*   **Web Scraping (WKWebView) & API Entegrasyonu:** Belediyelerin açık veri portallarından ve web sitelerinden canlı veri çekme.

## 🚀 Kurulum

1.  Projeyi klonlayın:
    ```bash
    git clone https://github.com/kullaniciadi/suIzim.git
    ```
2.  Xcode ile `suİzim.xcodeproj` dosyasını açın.
3.  Signing & Capabilities sekmesinden kendi Geliştirici Hesabınızı seçin.
4.  Simulator veya fiziksel cihazınızda çalıştırın.

## ⚠️ Notlar

*   Uygulama, verileri çekmek için internet bağlantısı gerektirir.
*   Baraj verileri ilgili belediyelerin web servislerinden veya web sitelerinden çekilmektedir; kaynak taraflı değişikliklerde veri akışı kesilebilir.

## 📄 Lisans

Bu proje MIT Lisansı ile lisanslanmıştır.
