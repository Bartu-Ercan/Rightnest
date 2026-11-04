# Rightnest kurulumu

Bu sürüm **0.1.0 erken erişim** sürümüdür. Yalnız Apple Silicon Mac’ler içindir. [Son sürümün sayfasını açın](https://github.com/Bartu-Ercan/Rightnest/releases/latest), Assets bölümünden `Rightnest-0.1.0-arm64.dmg` dosyasını indirin.

Öncelikli uygulamalar Safari ve Chrome’dur. Diğer uygulamalar otomatik değerlendirilir; destek garantisi verilmez. Güvenli boşluk bulunamazsa kontroller gizlenir. Uygulama bazında kapatma Ayarlar → Uygulamalar bölümündedir. API alt sınırı macOS13; gerçek cihaz testi macOS27.0(26A428)/Apple Silicon üzerinde yapılmıştır. Önceki macOS sürümleri ve temiz kullanıcı kurulum/güncelleme akışı tam doğrulanmadı.

## Kurulum

1. DMG’yi açın. Özel kurulum penceresinde Rightnest ve Applications görünür. Rightnest’i Applications’ın üzerine sürükleyin. Disk görüntüsünü çıkarın.
2. Kurulu kopyayı açın. Aynı anda eski Starboard ve Rightnest kopyalarını çalıştırmayın.
3. Önce izin gerektirmeyen deneme penceresini kullanın.
4. **Pencere kontrolünü ayarla…** düğmesine basın. Sistem Ayarları → Gizlilik ve Güvenlik altında uygulamanın pencere kontrol iznini açın. Test edilen macOS 27’de bölümün İngilizce adı “Device Control and Data Access”; önceki sürümlerde “Accessibility”.
5. Uygulamaya dönün. Gerçek izin algılandığında Hazır görünür. **Diğer uygulamalarda kontrolleri otomatik yerleştir** seçeneğini açın; normal bir Safari/Chrome penceresinde veya TextEdit denemesinde kontrol edin. Ardından **Menü çubuğunda devam et** seçeneğini kullanın.

Apple Developer ID imzası ve notarizasyon yoktur. macOS indirilen uygulamayı engelleyebilir; kurumsal cihazlarda çalıştırmak mümkün olmayabilir. Kaynağı kontrol ettikten sonra sistemin sunduğu uygulamaya özel açma seçeneğini değerlendirebilirsiniz. Gatekeeper’ı kapatmak veya Terminal’den karantinayı kaldırmak kurulum yöntemi değildir.

## Kullanım

Sıra: küçült, ekrana sığdır/geri yükle, kapat. Soldaki özgün düğmeler kalır. Başlık alanı dolu veya belirsizse pencerenin hemen dışında doğrulanmış boş alan aranır. Dışarıda da yer yoksa kontroller gizlenir. Ses/parlaklık göstergesi başlık alanını geçici olarak kapattığında şerit sola kaymaz veya daralmaz; gizlenip aynı yerde ve boyutta geri görünür. Tam ekran pencerelerde gösterilmez. Ortadaki düğme Dock ve menü çubuğunu korur. Elle yeniden boyutlandırma eski geri yükleme kaydını geçersiz kılar.

Oturum açıldığında başlatma isteğe bağlıdır ve başlangıçta kapalıdır. Menüden duraklatabilir, ayarları açabilir veya çıkabilirsiniz.

## Güncelleme ve kaldırma

Güncellemeden önce çıkın, Applications’taki aynı kopyayı yenisiyle değiştirin ve yeniden açın. Otomatik güncelleme yoktur. İzin sorunu varsa doğru kopyanın listelendiğini kontrol edin; uygulama içindeki Finder düğmesi dosyayı gösterir.

Kaldırmak için oturumda başlatmayı kapatın, uygulamadan çıkın ve Çöp Sepeti’ne taşıyın. İzin sayfasındaki kaydı da kaldırabilirsiniz. Ayrı bir yönetici hizmeti kurulmaz.

Temiz kullanıcı hesabı ve internetten indirilmiş paket deneyimi henüz doğrulanmadı. Ayrıntılar: INSTALL.md ve validation.md.
