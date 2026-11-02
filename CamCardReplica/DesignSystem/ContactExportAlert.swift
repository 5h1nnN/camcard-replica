import SwiftUI
import UIKit

enum ContactExportNotice: Identifiable {
    case success(created: Bool)
    case permissionDenied
    case restricted
    case failure(String)

    var id: String {
        switch self {
        case let .success(created): created ? "created" : "updated"
        case .permissionDenied: "permissionDenied"
        case .restricted: "restricted"
        case .failure: "failure"
        }
    }
}

private struct ContactExportAlertModifier: ViewModifier {
    @Binding var notice: ContactExportNotice?

    func body(content: Content) -> some View {
        content.alert(item: $notice) { notice in
            switch notice {
            case let .success(created):
                Alert(
                    title: Text(created ? "已存入系统通讯录" : "已更新系统通讯录"),
                    message: Text(created ? "联系人已保存，可在系统“通讯录”App 中查看。" : "联系人信息已同步为名片中的最新内容。"),
                    dismissButton: .default(Text("完成"))
                )
            case .permissionDenied:
                Alert(
                    title: Text("无法访问通讯录"),
                    message: Text("请在系统设置中允许 Cardly 访问通讯录，然后重试。"),
                    primaryButton: .default(Text("前往设置")) {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            case .restricted:
                Alert(
                    title: Text("通讯录访问受限"),
                    message: Text("此设备的系统限制不允许 App 写入通讯录。"),
                    dismissButton: .default(Text("知道了"))
                )
            case let .failure(message):
                Alert(
                    title: Text("无法存入通讯录"),
                    message: Text(message),
                    dismissButton: .default(Text("知道了"))
                )
            }
        }
    }
}

extension View {
    func contactExportAlert(notice: Binding<ContactExportNotice?>) -> some View {
        modifier(ContactExportAlertModifier(notice: notice))
    }
}
