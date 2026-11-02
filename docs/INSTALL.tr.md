# Rightnest kurulumu

Bu sürüm geliştirici önizlemesidir. Yalnız Apple Silicon hedeflenir; etkin dış uygulama desteği TextEdit ile sınırlıdır. Henüz herkese açık indirme yoktur.

## Kurulum

1. Sürüm numaralı DMG’yi açıp Rightnest’i Applications’a sürükleyin. Disk görüntüsünü çıkarın.
2. Kurulu kopyayı açın. Aynı anda eski Starboard ve Rightnest kopyalarını çalıştırmayın.
3. Önce izin gerektirmeyen deneme penceresini kullanın.
4. **Pencere kontrolünü ayarla…** düğmesine basın. Sistem Ayarları → Gizlilik ve Güvenlik altında uygulamanın pencere kontrol iznini açın. Test edilen macOS 27’de bölümün İngilizce adı “Device Control and Data Access”; önceki sürümlerde “Accessibility”.
5. Uygulamaya dönün. Gerçek izin algılandığında Hazır görünür. TextEdit’te deneyip **Menü çubuğunda devam et** seçeneğini kullanın.

Apple Developer ID imzası ve notarizasyon yoktur. macOS indirilen uygulamayı engelleyebilir; kurumsal cihazlarda çalıştırmak mümkün olmayabilir. Kaynağı kontrol ettikten sonra sistemin sunduğu uygulamaya özel açma seçeneğini değerlendirebilirsiniz. Gatekeeper’ı kapatmak veya Terminal’den karantinayı kaldırmak kurulum yöntemi değildir.

## Kullanım

Sıra: küçült, ekrana sığdır/geri yükle, kapat. Soldaki özgün düğmeler kalır. Dolu veya doğrulanamayan alanda sağ kontroller gizlenir. Tam ekran pencerelerde gösterilmez. Ortadaki düğme Dock ve menü çubuğunu korur. Elle yeniden boyutlandırma eski geri yükleme kaydını geçersiz kılar.

Oturum açıldığında başlatma isteğe bağlıdır ve başlangıçta kapalıdır. Menüden duraklatabilir, ayarları açabilir veya çıkabilirsiniz.

## Güncelleme ve kaldırma

Güncellemeden önce çıkın, Applications’taki aynı kopyayı yenisiyle değiştirin ve yeniden açın. Otomatik güncelleme yoktur. İzin sorunu varsa doğru kopyanın listelendiğini kontrol edin; uygulama içindeki Finder düğmesi dosyayı gösterir.

Kaldırmak için oturumda başlatmayı kapatın, uygulamadan çıkın ve Çöp Sepeti’ne taşıyın. İzin sayfasındaki kaydı da kaldırabilirsiniz. Ayrı bir yönetici hizmeti kurulmaz.

Temiz kullanıcı hesabı ve internetten indirilmiş paket deneyimi henüz doğrulanmadı. Ayrıntılar: INSTALL.md ve validation.md.
