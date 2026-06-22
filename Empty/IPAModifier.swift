import Foundation

class IPAModifier {
    
    // Hàm xử lý chính: Nhập file IPA -> Sửa Info.plist -> Chuẩn bị xuất
    static func modifyMinimumOSVersion(ipaURL: URL, toVersion: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let fileManager = FileManager.default
        let tmpDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        do {
            // 1. Tạo thư mục tạm để giải nén
            try fileManager.createDirectory(at: tmpDirectory, withIntermediateDirectories: true, attributes: nil)
            
            // 2. Đổi đuôi .ipa thành .zip tạm thời để chuẩn bị giải nén
            let zipURL = tmpDirectory.appendingPathComponent("app.zip")
            try fileManager.copyItem(at: ipaURL, to: zipURL)
            
            // GHI CHÚ KỸ THUẬT: Để giải nén trực tiếp bằng Swift không cần thư viện ngoài trên iOS,
            // chúng ta có thể gọi qua tiến trình hệ thống hoặc dùng Apple Archive (iOS 14+).
            // Dưới đây là logic xử lý sau khi đã bung được thư mục Payload:
            
            // 3. Tìm file Info.plist bên trong thư mục Payload
            // Đường dẫn giả định: tmpDirectory/Payload/[Tên_App].app/Info.plist
            let payloadURL = tmpDirectory.appendingPathComponent("Payload")
            
            // Quét tìm thư mục con `.app`
            let contents = try fileManager.contentsOfDirectory(at: payloadURL, includingPropertiesForKeys: nil)
            guard let appBundleURL = contents.first(where: { $0.pathExtension == "app" }) else {
                throw NSError(domain: "EmptyError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy thư mục .app trong Payload"])
            }
            
            let plistURL = appBundleURL.appendingPathComponent("Info.plist")
            
            // 4. ĐỌC và SỬA file Info.plist (Binary Plist -> Dictionary -> Ghi đè)
            let plistData = try Data(contentsOf: plistURL)
            
            // Giải mã file Plist thành Dictionary trong Swift
            var propertyListFormat = PropertyListSerialization.PropertyListFormat.binary
            guard var plistDict = try PropertyListSerialization.propertyList(from: plistData, options: .mutableContainersAndLeaves, format: &propertyListFormat) as? [String: Any] else {
                throw NSError(domain: "EmptyError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Không thể cấu trúc hóa file Info.plist"])
            }
            
            // Thực hiện sửa đổi (Hạ MinimumOSVersion)
            print("[Empty] Cũ: \(plistDict["MinimumOSVersion"] ?? "Không rõ")")
            plistDict["MinimumOSVersion"] = toVersion
            print("[Empty] Đã sửa thành: \(toVersion)")
            
            // Mã hóa ngược lại thành định dạng định sẵn của Apple
            let updatedPlistData = try PropertyListSerialization.data(fromPropertyList: plistDict, format: .binary, options: 0)
            try updatedPlistData.write(to: plistURL)
            
            // 5. Đóng gói ngược lại (Zip) thành file IPA mới
            let outputIPAURL = fileManager.temporaryDirectory.appendingPathComponent("Empty_Modified_\(UUID().uuidString).ipa")
            
            // Logic nén lại thư mục Payload thành file outputIPAURL...
            
            completion(.success(outputIPAURL))
            
        } catch {
            completion(.failure(error))
        }
    }
}