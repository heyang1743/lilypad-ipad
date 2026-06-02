import SwiftUI
import PDFKit

struct PDFKitPreview: UIViewRepresentable {
    let data: Data?

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = UIColor.secondarySystemBackground
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if let data, !data.isEmpty {
            uiView.document = PDFDocument(data: data)
            uiView.autoScales = true
        } else {
            uiView.document = nil
        }
    }
}
