import SwiftUI

struct DownloadProgress: View {
    let percent: Int

    var body: some View {
        HStack(spacing: 6) {
            ProgressView(value: Double(percent), total: 100)
                .progressViewStyle(.circular)
                .controlSize(.small)
            Text("\(percent)%")
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .help("Downloading video")
    }
}
