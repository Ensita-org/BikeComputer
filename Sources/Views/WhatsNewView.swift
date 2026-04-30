import SwiftUI

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Image(systemName: "bicycle.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.blue)
                    .padding(.top, 48)

                Text("What's New in 1.1")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 40)

            VStack(alignment: .leading, spacing: 28) {
                FeatureRow(
                    icon: "globe",
                    color: .blue,
                    title: "Multi-Language Support",
                    description: "The app is now available in French, Spanish, and Polish. Switch language anytime in Settings."
                )
                FeatureRow(
                    icon: "square.and.arrow.down",
                    color: .green,
                    title: "GPX Import",
                    description: "Import rides from GPX files or ZIP archives directly into the app."
                )
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .interactiveDismissDisabled()
    }
}

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    WhatsNewView()
}
