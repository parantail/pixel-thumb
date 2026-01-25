import SwiftUI

struct StatusBarView: View {
    let message: String
    let folderPath: String?

    var body: some View {
        HStack {
            if let path = folderPath {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.secondary)
                Text(path)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(.secondary)

                Divider()
                    .frame(height: 12)
            }

            Text(message)
                .foregroundStyle(.primary)

            Spacer()
        }
        .font(.system(size: 11))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.appToolbar)
    }
}
