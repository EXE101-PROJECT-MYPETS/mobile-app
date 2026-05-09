# AGENTS.md

Huong dan cho cac agent lam viec trong repo `petpee_mobile`.

## Tong quan

Day la ung dung Flutter mobile cho PetPee. App hien co cac luong chinh: home,
auth, product, spa booking, cart, checkout, profile, pets va shop detail.
Backend moi duoc tich hop cho auth; phan con lai dang dung mock data trong
`AppState`.

## Lenh thuong dung

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
```

Neu thay doi launcher icon:

```bash
dart run flutter_launcher_icons
```

## Kien truc

- Entry point: `lib/main.dart`
- Route table: `MaterialApp.routes` trong `lib/app.dart`
- State:
  - `lib/common/store/app_state.dart`: mock products, cart, pets, addresses,
    likes va recently viewed.
  - `lib/common/auth/store/auth_provider.dart`: login/register/logout, token va
    user hien tai.
- Config API: `lib/common/config/api_config.dart`
- Feature modules:
  - `apps/home`
  - `apps/product`
  - `apps/cart`
  - `apps/checkout`
  - `apps/profile`
  - `apps/shop`
- Common modules:
  - `common/address`
  - `common/auth`
  - `common/component`
  - `common/config`
  - `common/store`
  - `common/toast`
  - `common/user`
- Shared widget: `lib/common/component/product_card.dart`

## Quy uoc code

- Giu cau truc `apps`/`common` hien tai: man hinh va model domain dat trong
  `lib/apps/<domain>`, con auth/config/state/widget dung chung dat trong
  `lib/common`.
- Dung `Provider`/`ChangeNotifier` theo pattern co san truoc khi them state
  management moi.
- Dung `Hive` cho local persistence nhe; cac box dang dung la `auth_box` va
  `user_preferences`.
- Khong hard-code endpoint trong screen/provider moi. Dua URL vao
  `ApiConfig` hoac service tuong ung.
- Moi feature/domain phai tach folder theo dung trach nhiem khi co phan do:
  - `model/`: DTO/model/request/response, `fromJson`, `toJson`, helper build
    multipart fields.
  - `api/`: service goi HTTP/backend; parse response ve DTO, khong tra
    `Map<String, dynamic>` tho len provider/page.
  - `component/`: widget con dung rieng trong feature/domain.
  - `page/`: screen/page.
  - `store/`: Provider/ChangeNotifier/state domain neu can.
- Khi them API tu BE, doc type/DTO tu FE va BE truoc, roi dat ten class/field
  Flutter trung voi contract dang co. Vi du auth dung `UserLoginResponse`,
  `AuthShopDTO`, `AuthenticationRequest`, `RegisterRequest`, `accessToken`,
  `refreshToken`, `currentShopId`, `avatarUrlPreview`.
- UI hien dung Material, `GoogleFonts.inter`, `lucide_icons` va tone hong
  PetPee. Khi them man hinh, uu tien style gan voi cac screen hien co.
- Chuoi hien thi trong app la tieng Viet. Giu file o UTF-8 va tranh sua nham
  cac chuoi tieng Viet thanh text loi ma hoa.
- Neu them asset runtime, khai bao trong `flutter/assets` cua `pubspec.yaml`.
  `assets/app_icon.png` hien chi duoc dung cho launcher icon config.

## Auth va backend

- DTO auth nam trong `lib/common/auth/model/auth_dto.dart`, theo FE
  `UserLoginResponse`.
- `AuthService.login()` nhan `AuthenticationRequest`, goi
  `ApiConfig.customerLoginUrl` voi JSON `email/password`, tra
  `UserLoginResponse`.
- `AuthService.register()` nhan `RegisterRequest`, goi `ApiConfig.registerUrl`
  bang multipart form, gom `email`, `password`, `fullName`, `phone`, `address`,
  `province`, `district`, `ward`, `hamlet`, tuy chon `age`,
  `avatarUrlPreview`, tra `UserLoginResponse`.
- `AuthProvider` luu `access_token`, `refresh_token`, `role`,
  `current_shop_id`, `shops` va `user_data` trong Hive box `auth_box`.
- Tinh/thanh, quan/huyen, phuong/xa tren man dang ky dung
  `common/address/vietnam_address_service.dart` voi API
  `https://provinces.open-api.vn/api/v1`; `hamlet` van nhap tay.
- Avatar URL trong profile duoc ghep tu `ApiConfig.baseUrl` bo phan `/api`.

## Testing

- Khi test widget co dung `HomeScreen`, `MyApp` hoac screen dung Provider, boc
  widget bang `MultiProvider` voi `AppState` va `AuthProvider`.
- Code dung Hive can khoi tao Hive truoc test va cleanup box sau test neu test
  co ghi local storage.
- Truoc khi ket thuc mot thay doi code, chay toi thieu `dart format lib test`
  va `flutter analyze`; chay `flutter test` khi thay doi logic/UI co the test.
