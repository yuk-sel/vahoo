# 👥 İki Kişilik Bağımsız Proje Görev Dağılımı ve Çalışma Planı

Bu doküman, **Restoran İşletim Sistemi** projesinde iki geliştiricinin (Geliştirici A ve Geliştirici B) birbirine bağımlı kalmadan, paralel ve çakışmasız biçimde çalışabilmesi için hazırlanmıştır.

---

## 🎯 Temel Çalışma Prensibi

1. **Tam Bağımsızlık (Decoupling):** Geliştirici A sadece Müşteri/QR tarafına (`apps/customer-client`), Geliştirici B ise Backend ve Yönetim Paneli tarafına (`server` ve `apps/admin-dashboard`) odaklanır.
2. **API Sözleşmesi Bağımlılığı:** Her iki taraf da geliştirmeye başlamadan önce `docs/api-spec.json` dosyasında tanımlanan veri formatı ve endpoint kuralları üzerinde mutabık kalır.
3. **Mock Veri Kullanımı:** Backend tarafı henüz hazır olmasa bile Geliştirici A, `api-spec.json` içerisindeki örnek verileri yerel state/mock servis olarak kullanarak tüm arayüzü geliştirebilir.

---

## 👤 GELİŞTİRİCİ A: Müşteri Deneyimi & QR Arayüzü

* **Sorumlu Olduğu Dizin:** `apps/customer-client/`
* **Odak Noktası:** Müşterinin masada QR okutmasıyla başlayan PWA / Responsive mobil web tecrübesi.

### 📋 Görev Listesi

#### 1. QR ve Masa Oturumu Yönetimi
- [ ] URL'den masa parametresini okuma (`/m/table-12` veya `qrCode` token).
- [ ] Masa oturumu başlatma, LocalStorage/SessionStorage üzerinde oturum bilgisini saklama.
- [ ] Yanlış veya geçersiz QR okutulduğunda hata ekranı gösterme.

#### 2. Menü ve Arayüz Bileşenleri
- [ ] Kategori listesi (Yemekler, Burgerler, İçecekler vb.) ve yatay/dikey kaydırma mekanizması.
- [ ] Ürün kartı bileşeni (Görsel, İsim, Fiyat, İçindekiler, Alerjen ikonları).
- [ ] **Ürün Opsiyon Modalı:** Boyut seçimi (Tekli), Ekstra malzeme seçimi (Çoklu), Özel not alanı.
- [ ] Ürün arama ve filtreleme çubuğu.

#### 3. Sepet ve Sipariş Verme Akışı
- [ ] Sepet çekmecesi (Drawer) / Sepet sayfası.
- [ ] Sepetteki ürünlerin adetlerini artırma, azaltma, silme ve sipariş notu düzenleme.
- [ ] Toplam fiyat hesaplama (Ekstra opsiyonlar dahil).
- [ ] "Siparişi Gönder" butonu, yükleniyor (loading) ve onay durumları.

#### 4. Canlı Sipariş Takip Ekranı
- [ ] Sipariş alındıktan sonra gösterilecek durum ekranı (#1042 - Hazırlanıyor).
- [ ] WebSocket / Polling kullanarak backend'den gelen sipariş durum güncellemelerini ekrana yansıtma.

#### 5. Masa Hizmetleri
- [ ] "🔔 Garson Çağır" butonu ve modal onayı.
- [ ] "💳 Hesap İste" butonu.

---

## 👤 GELİŞTİRİCİ B: Backend Core & Restoran Yönetim Paneli

* **Sorumlu Olduğu Dizinler:** `server/` ve `apps/admin-dashboard/`
* **Odak Noktası:** Veritabanı mimarisi, REST/WebSocket API'leri, Admin Paneli ve Mutfak Ekranı (KDS).

### 📋 Görev Listesi

#### 1. Veritabanı & Backend Altyapısı
- [ ] Veritabanı şemasını kurma (Restaurants, Tables, Categories, Products, OptionGroups, Orders, OrderItems, Users).
- [ ] REST API Endpoint'lerini yazma (CRUD: Menü yönetimi, Sipariş yönetimi, Masa yönetimi).
- [ ] **Güvenlik & İş Mantığı:** Frontend'den gelen fiyatı reddedip sipariş tutarını DB üzerinden hesaplayan güvenli sipariş servisi (`orderService.js`).
- [ ] JWT tabanlı yetkilendirme ve Rol Bazlı Erişim Kontrolü (Admin, Garson, Mutfak).
- [ ] WebSocket sunucu altyapısını kurma (Anlık sipariş ve bildirim yayınları).

#### 2. Restoran Yönetim Paneli (Admin UI)
- [ ] **Dashboard:** Anlık bekleyen sipariş, hazırlanan sipariş ve günlük ciro özet kartları.
- [ ] **Sipariş Yönetim Ekranı:** Gelen siparişleri listeleme ve durum değiştirme (Yeni → Onaylandı → Hazırlanıyor → Hazır → Teslim Edildi).
- [ ] **Menü Yönetimi:** Kategori ve ürün ekleme/düzenleme/silme, "Tükendi / Stokta Yok" pasifleştirme anahtarı.
- [ ] **Masa & QR Yönetimi:** Masaları tanımlama ve masa bazlı QR kod çıktısı oluşturma.

#### 3. Mutfak Ekranı (KDS) & Bildirim Sistemleri
- [ ] Mutfak için dokunmatik/tablet uyumlu sade sipariş hazırlama ekranı.
- [ ] Yeni sipariş ve garson çağrılarında sesli/görsel anlık bildirim mekanizması.
- [ ] Sipariş geçmişi ve basit satış raporlama ekranı.

---

## 🤝 Ortak İlk Adım: API Sözleşmesi

Geliştirmeye başlamadan önce iki geliştirici de `docs/api-spec.json` dosyasını incelemeli ve üzerinde anlaşmalıdır. 

- **İstek Formatı:** `POST /api/v1/orders` isteğinde gönderilecek JSON yapısı.
- **Yanıt Formatı:** `GET /api/v1/tables/{qrCode}/menu` isteğinden dönecek menü ve opsiyon yapısı.
- **WebSocket Event Adları:** `new_order`, `order_status_updated`, `waiter_call`