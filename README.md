# 📦 MySSO SDK – Integration Guide

## 1. Add Dependency (AppAuth)

Thêm thư viện **AppAuth** thông qua Swift Package Manager:

- Repository: https://github.com/openid/AppAuth-iOS

### Cách thêm:

1. Mở Xcode  
2. Chọn **File → Add Packages**  
3. Nhập URL: https://github.com/openid/AppAuth-iOS
4. Chọn version 2.0.0  

---

## 2. Build SDK

Chạy script sau để build `xcframework`:

```bash
sh ./build_xcframework.sh

## 3. Run Demo

Embed & Sign MySSOSDK.framework tại thư mục /build (Đã build ở B2) vào các SSOAppDemo, SSOAppDemo2
