# Pawly Mobile

Pawly Mobile la ung dung Flutter cho chu thu cung, tap trung vao mua sam san
pham, dat dich vu spa/thu y, quan ly gio hang, dia chi, thu cung va thong tin
tai khoan.

## Tinh nang hien co

- Trang chu voi banner, quick actions, danh muc, dich vu noi bat, ban do spa mo
  phong va luoi san pham.
- Dang nhap/dang ky khach hang qua backend, co ho tro upload avatar khi dang ky.
- Danh sach san pham, chi tiet san pham, yeu thich, lich su xem gan day va goi
  y san pham tu danh muc da xem.
- Dat dich vu spa voi chon goi, ngay gio, xac nhan lich hen va man hinh thanh
  cong.
- Gio hang, chon san pham, tang giam so luong, xoa san pham va luong checkout.
- Ho so nguoi dung, don hang, thu cung cua toi, san pham da thich, da xem gan
  day va cai dat/dang xuat.

## Tech stack

- Flutter/Dart, SDK constraint: `^3.10.7`
- State management: `provider`
- Local storage: `hive`, `hive_flutter`
- API client: `http`
- UI/assets: `google_fonts`, `lucide_icons`, `cupertino_icons`, `image_picker`
- Tooling: `flutter_lints`, `flutter_launcher_icons`

## Cau truc thu muc

```text
lib/
  app.dart                          # Root router va route definitions
  main.dart                         # Flutter entry point, Hive va Provider setup
  apps/
    cart/
      model/cart_item_model.dart
      page/cart_screen.dart
    checkout/
      model/address_model.dart
      page/                         # Dia chi va thanh toan
    home/
      page/                         # Home va notifications
    product/
      model/product_model.dart
      page/                         # Product detail/list va spa booking
    profile/
      model/pet_model.dart
      page/                         # Profile, pets, favorites, settings
    shop/
      page/shop_detail_screen.dart
  common/
    auth/
      api/auth_service.dart
      model/auth_dto.dart             # DTO auth theo FE/BE
      page/                         # Login, register, forgot password
      store/auth_provider.dart
    address/vietnam_address_service.dart
    component/product_card.dart      # Card san pham dung lai
    config/api_config.dart          # Backend base URL va endpoint auth
    store/app_state.dart            # AppState va mock state
    toast/app_toast.dart             # Toast overlay dung chung
    user/model/user_model.dart
test/
  widget_test.dart
assets/
  app_icon.png                      # Icon nguon cho flutter_launcher_icons
```

## Cai dat va chay

1. Cai Flutter SDK phu hop voi `pubspec.yaml`.
2. Lay dependency:

```bash
flutter pub get
```

3. Chay app:

```bash
flutter run
```

4. Kiem tra chat luong truoc khi merge:

```bash
dart format lib test
flutter analyze
flutter test
```

## Cau hinh backend

Endpoint backend nam trong `lib/common/config/api_config.dart`.

```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.1.26:8080/api',
);
```

- Neu chay tren Android Emulator va backend o may host, dung
  `http://10.0.2.2:<port>/api`.
- Neu chay tren thiet bi that, dung IPv4 LAN cua may chay backend.
- Co the override khong can sua code:
  `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api`.
- Hien tai app chi goi backend cho auth:
  - `POST /auth/customer/login`
  - `POST /auth/register`
- Register gui multipart gom `email`, `password`, `fullName`, `phone`,
  `address`, `province`, `district`, `ward`, `hamlet`, tuy chon `age` va
  `avatarUrlPreview`.
- Tinh/thanh, quan/huyen, phuong/xa dung API ngoai
  `https://provinces.open-api.vn/api/v1`.
- Cac du lieu san pham, gio hang va thu cung hien van la mock data trong
  `AppState`.

## Ghi chu phat trien

- `main()` khoi tao Hive va boc app bang `MultiProvider` gom `AuthProvider` va
  `AppState`; route table nam trong `lib/app.dart`.
- `AuthProvider` luu `access_token`, `refresh_token`, `role`, `current_shop_id`,
  `shops` va `user_data` trong Hive box `auth_box`.
- API auth phai map qua DTO trong `common/auth/model/auth_dto.dart`, khong tra
  `Map<String, dynamic>` tho ra provider/page.
- `AppState` luu lich su danh muc/san pham da xem trong Hive box
  `user_preferences`.
- `ProductModel.type` dieu huong UI: `spa` mo luong spa, cac loai khac mo chi
  tiet san pham.
- Neu doi icon app, cap nhat `assets/app_icon.png` roi chay:

```bash
dart run flutter_launcher_icons
```

## Quy uoc module

- Moi domain/feature duoi `lib/apps/<feature>` hoac shared domain duoi
  `lib/common/<domain>` nen tach folder theo trach nhiem:
  - `model/`: model, DTO, request/response, `fromJson`, `toJson` va helper build
    multipart fields.
  - `api/`: service goi HTTP/backend. API service parse response ve DTO, khong
    day `Map<String, dynamic>` tho len page/provider.
  - `component/`: widget con dung rieng trong feature/domain do.
  - `page/`: screen/page.
  - `store/`: Provider/ChangeNotifier hoac state cua domain neu can.
- Khi them API tu BE, doc type/DTO tu FE va BE truoc, roi dat ten class/field
  Flutter trung voi contract dang co. Vi du auth dang dung `UserLoginResponse`,
  `AuthShopDTO`, `AuthenticationRequest`, `RegisterRequest`, `accessToken`,
  `refreshToken`, `currentShopId`, `avatarUrlPreview`.
- Khong hard-code endpoint trong page/component; dua URL vao `ApiConfig` va goi
  qua service trong folder `api/`.
