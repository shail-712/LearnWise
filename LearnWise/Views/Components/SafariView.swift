import SafariServices
import SwiftUI

/// In-app browser (SFSafariViewController), so students stay inside LearnWise.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

/// A URL that can drive `.sheet(item:)`.
struct BrowserLink: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

extension View {
    /// Opens every http(s) link in this view hierarchy in an in-app Safari sheet,
    /// including `Link`s and `openURL` calls. Other schemes (mailto:, tel:) go to the system.
    func opensLinksInApp() -> some View {
        modifier(InAppBrowserModifier())
    }
}

private struct InAppBrowserModifier: ViewModifier {
    @State private var link: BrowserLink?

    func body(content: Content) -> some View {
        content
            .environment(\.openURL, OpenURLAction { url in
                guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
                    return .systemAction
                }
                link = BrowserLink(url: url)
                return .handled
            })
            .sheet(item: $link) { link in
                SafariView(url: link.url)
                    .ignoresSafeArea()
            }
    }
}
