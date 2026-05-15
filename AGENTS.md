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
## UI Layout Safety Rules

- Khi làm giao diện, bắt buộc kiểm tra nguy cơ vỡ layout, overflow, text tràn, nút bị che hoặc nội dung bị cắt.
- Không đặt chiều cao cố định quá chặt cho card, modal, bottom sheet, form hoặc list item nếu bên trong có text/dữ liệu động.
- Ưu tiên layout co giãn theo nội dung bằng `Flexible`, `Expanded`, `Wrap`, `SingleChildScrollView`, `ListView`, `mainAxisSize`, `min/max constraints` thay vì hard-code height.
- Với text dài, phải xử lý bằng `maxLines`, `overflow: TextOverflow.ellipsis`, hoặc cho phép xuống dòng hợp lý.
- Với giá tiền, tên dịch vụ, tên shop, địa chỉ, mô tả và badge khoảng cách, phải giả định dữ liệu có thể dài hơn mẫu thiết kế.
- Khi sửa UI card/list item, phải test với dữ liệu dài và dữ liệu ngắn để tránh lỗi overflow.
- Không để các thành phần trong `Column` bị ép quá sát nhau. Cần dùng spacing hợp lý và tránh tổng chiều cao con vượt quá chiều cao cha.
- Nếu dùng Flutter, không để `Column` trong container/card có height cố định mà không có xử lý overflow.
- Nếu dùng Flutter, khi có ảnh + nội dung + giá + badge trong cùng card, card phải đủ cao hoặc nội dung bên dưới phải được co giãn an toàn.
- Nếu gặp lỗi `BOTTOM OVERFLOWED`, phải ưu tiên sửa layout thật, không chỉ che lỗi bằng cách tăng height tùy tiện.

## Vietnamese UI Text Rule

- Tất cả chữ hiển thị trên giao diện người dùng phải dùng tiếng Việt có dấu.
- Áp dụng cho: tiêu đề trang, nhãn form, placeholder, tooltip, nút bấm, tab, menu, breadcrumb, thông báo lỗi, thông báo thành công, confirm dialog, empty state, table header, filter label và mọi text mà người dùng nhìn thấy.
- Không dùng tiếng Việt không dấu trong UI, ví dụ dùng `Cấu hình GHTK`, không dùng `Cau hinh GHTK`.
- Không hard-code text tiếng Anh trên UI nếu màn hình dành cho người dùng Việt, ví dụ dùng `Lưu`, `Hủy`, `Tìm kiếm`, `Đang tải...`, `Không có dữ liệu`.
- Chỉ giữ tiếng Anh cho tên biến, tên hàm, tên class, tên file, API path, enum, package, keyword kỹ thuật và giá trị kỹ thuật không hiển thị trực tiếp cho người dùng.
- Nếu backend trả về enum hoặc mã trạng thái tiếng Anh, frontend phải map sang nhãn tiếng Việt có dấu trước khi hiển thị, ví dụ `PENDING` → `Đang chờ`, `CONFIRMED` → `Đã xác nhận`.
- Khi thêm hoặc sửa component, phải rà soát các text hiển thị trong phần component đó và chuyển sang tiếng Việt có dấu nếu còn thiếu.