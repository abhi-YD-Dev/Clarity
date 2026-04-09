

import SwiftUI
import AVFoundation

struct AudioPlaybackRow: View {
  
    let audioData: Data 
    
    @StateObject private var playbackDelegate = AudioPlaybackDelegate()
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        HStack(spacing: 16) {
            
            Button {
                togglePlay()
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.orange, .orange.opacity(0.2))
                    .shadow(color: .orange.opacity(isPlaying ? 0.5 : 0), radius: 8)
            }
            .accessibilityLabel(isPlaying ? "Pause voice recording" : "Play voice recording")
            .accessibilityHint("Double tap to \(isPlaying ? "pause" : "play") the recorded answer")
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Voice Recall")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                
                Text(isPlaying ? "Playing..." : "Tap to listen")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            Image(systemName: "waveform")
                .font(.title2)
                .foregroundColor(isPlaying ? .orange : .white.opacity(0.2))
                .scaleEffect(isPlaying ? 1.15 : 1.0)
                .opacity(isPlaying ? 1.0 : 0.5)
                .animation(
                    isPlaying ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default,
                    value: isPlaying
                )
                .accessibilityHidden(true)
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .onAppear(perform: setupPlayer)
        .onDisappear {
            audioPlayer?.stop()
            isPlaying = false
        }
        .onChange(of: playbackDelegate.didFinish) {
            if playbackDelegate.didFinish {
                withAnimation { isPlaying = false }
                playbackDelegate.didFinish = false
            }
        }
    }
    
    private func setupPlayer() {
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.delegate = playbackDelegate
            audioPlayer?.prepareToPlay()
        } catch {
            print("Failed to load audio: \(error)")
        }
    }
    
    private func togglePlay() {
        guard let player = audioPlayer else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        
        withAnimation {
            isPlaying.toggle()
        }
    }
}

// MARK: - AVAudioPlayerDelegate

@MainActor
class AudioPlaybackDelegate: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var didFinish = false

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        MainActor.assumeIsolated {
            self.didFinish = true
        }
    }
}
