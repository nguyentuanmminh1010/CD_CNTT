/// Điền Client ID/App ID thật vào đây khi đã đăng ký trên Google Cloud Console
/// / Meta for Developers (xem CLAUDE.md > Kiến trúc Backend > OAuth). Để trống
/// thì nút Google/Facebook sẽ hiện thông báo "chưa cấu hình" thay vì gọi SDK
/// (tránh lỗi khó hiểu từ SDK khi chưa có cấu hình nền tảng tương ứng).
const String googleSignInClientId =
    '763477988188-j4pb1ntmed6nar0ng5s8c9ndjh0okb2h.apps.googleusercontent.com';
const String facebookAppId = '1317749868090961';

/// Quyền xin khi đăng nhập Facebook. Chỉ `public_profile` (luôn có sẵn): app trên Meta chưa thêm quyền
/// `email` vào use case "Xác thực và tạo tài khoản" nên xin `email` (mặc định của plugin) làm hộp thoại
/// Facebook báo "Invalid Scopes: email" và chặn đăng nhập với tài khoản admin/developer/tester.
/// Khi đã bật quyền `email` trên Meta (Use cases → Customize → email → Add) thì thêm 'email' vào đây để
/// backend gộp được tài khoản trùng email.
const List<String> facebookLoginPermissions = ['public_profile'];
