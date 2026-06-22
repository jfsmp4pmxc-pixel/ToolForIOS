import SwiftUI
import UniformTypeIdentifiers

struct MainView: View {
    @State private var targetVersion: String = "15.0"
    @State private var logText: String = "[Hệ thống] Sẵn sàng. Vui lòng chọn file IPA...\n"
    @State private var isShowingPicker = false
    @State private var selectedFileURL: URL?
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Ô nhập phiên bản iOS
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phiên bản iOS mục tiêu:")
                        .font(.headline)
                    TextField("Ví dụ: 15.0", text: $targetVersion)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                }
                .padding(.horizontal)
                
                // Nút chọn file IPA
                Button(action: {
                    isShowingPicker = true
                }) {
                    HStack {
                        Image(systemName: "doc.circle.fill")
                        Text(selectedFileURL == nil ? "📂 Chọn file IPA cần sửa" : "Đã chọn: \(selectedFileURL!.lastPathComponent)")
                    }
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isProcessing ? Color.gray : Color.blue)
                    .cornerRadius(10)
                }
                .disabled(isProcessing)
                .padding(.horizontal)
                
                // Hộp hiển thị Log tiến trình
                VStack(alignment: .leading) {
                    Text("Nhật ký tiến trình:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $logText)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        .disabled(true)
                }
                .padding(.horizontal)
                .frame(height: 250)
                
                Spacer()
            }
            .navigationTitle("Empty - IPA Tools")
            .sheet(isPresented: $isShowingPicker) {
                DocumentPicker(selectedURL: $selectedFileURL, logText: $logText, targetVersion: targetVersion)
            }
        }
    }
}

// Cấu trúc bổ trợ để gọi trình chọn File của iOS trong Swift
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?
    @Binding var logText: String
    var targetVersion: String
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType(filenameExtension: "ipa")!], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAtURLs urls: [URL]) {
            guard let url = urls.first else { return }
            parent.selectedURL = url
            parent.logText += "[+] Đã nhập file: \(url.lastPathComponent)\n"
            
            // Kích hoạt lõi sửa đổi ngay tại đây
            parent.logText += "[*] Đang phẫu thuật cấu trúc Plist...\n"
            IPAModifier.modifyMinimumOSVersion(ipaURL: url, toVersion: parent.targetVersion) { result in
                switch result {
                case .success(let outputURL):
                    parent.logText += "[+] Thành công! File mới đã sẵn sàng xuất.\n"
                    // Kích hoạt UI chia sẻ/xuất file ra ứng dụng Tệp
                case .failure(let error):
                    parent.logText += "[-] Lỗi: \(error.localizedDescription)\n"
                }
            }
        }
    }
}
