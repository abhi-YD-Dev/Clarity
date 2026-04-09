
import SwiftUI

/// Reusable media input button used in both `CreateTopicView` (solutions step)
/// and `TestWizardView` (answer step).
struct MediaInputButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                Text(label)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color.opacity(0.09))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add \(label.lowercased()) answer")
        .accessibilityHint("Double tap to add a \(label.lowercased()) input")
    }
}

/// Reusable solution/answer chip showing a media item with a delete button.
struct SolutionChipView: View {
    let media: SolutionMedia
    let accentColor: Color
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: media.type == .text ? "text.alignleft"
                           : media.type == .image ? "photo"
                           : "waveform")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(accentColor)
                .frame(width: 32, height: 32)
                .background(accentColor.opacity(0.12))
                .clipShape(Circle())

            Group {
                if media.type == .text {
                    Text(media.textContent ?? "")
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                } else if media.type == .image, let data = media.imageData, let img = UIImage(data: data) {
                    HStack(spacing: 8) {
                        Image(uiImage: img)
                            .resizable().scaledToFill()
                            .frame(width: 40, height: 30)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("Image")
                            .font(.system(.subheadline, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else if media.type == .voice, let data = media.audioData {
                    AudioPlaybackRow(audioData: data)
                } else if media.type == .voice {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Voice Recording")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)
                        Text("Audio attached")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }

            Spacer()

            Button {
                withAnimation(.spring()) { onRemove() }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
                    .frame(width: 24, height: 24)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(media.type == .text ? "text" : media.type == .image ? "image" : "voice") item")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.07), lineWidth: 1))
        .transition(.move(edge: .leading).combined(with: .opacity))
    }
}
