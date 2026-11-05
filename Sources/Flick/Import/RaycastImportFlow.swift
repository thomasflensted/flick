import AppKit
import FlickCore

enum RaycastImportFlow {
    static func run(into store: QuicklinkStore) -> Bool {
        NSApp.activate(ignoringOtherApps: true)
        guard let file = chooseFile() else { return false }
        var retry = false
        while let password = askPassword(retry: retry) {
            do {
                let links = try RaycastExport.quicklinks(fromJSON: RaycastDecryptor.decrypt(file, password: password))
                showResult(added: store.merge(links), total: links.count)
                return true
            } catch is RaycastDecryptor.WrongPassword {
                retry = true
            } catch {
                NSAlert(error: error).runModal()
                return false
            }
        }
        return false
    }

    private static func chooseFile() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose your Raycast export (.rayconfig)"
        panel.message = "In Raycast: Settings → Advanced → Export. Then pick the .rayconfig file here."
        panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        return panel.runModal() == .OK ? panel.url : nil
    }

    private static func askPassword(retry: Bool) -> String? {
        let alert = NSAlert()
        alert.messageText = "Raycast export password"
        alert.informativeText = retry
            ? "That didn't work. Check the export password and try again."
            : "Enter the password you set when exporting from Raycast."
        let field = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        alert.accessoryView = field
        alert.addButton(withTitle: "Import")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = field
        return alert.runModal() == .alertFirstButtonReturn ? field.stringValue : nil
    }

    private static func showResult(added: Int, total: Int) {
        let alert = NSAlert()
        alert.messageText = "Imported \(added) quicklinks"
        if added < total { alert.informativeText = "\(total - added) were already in Flick and were skipped." }
        alert.runModal()
    }
}
