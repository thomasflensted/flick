import AppKit

func textWidth(_ text: String, fontSize: CGFloat) -> CGFloat {
    ceil(NSAttributedString(string: text, attributes: [.font: NSFont.systemFont(ofSize: fontSize)]).size().width)
}
