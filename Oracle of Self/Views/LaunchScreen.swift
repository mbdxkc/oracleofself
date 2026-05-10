//
//  LaunchScreen.swift
//  Oracle of Self
//
//  Two-phase animated splash:
//    1. mediaBrilliance logo on black (~0.6 s hold, 0.6 s cross-fade)
//    2. Oracle of Self logo on white, large (0.7 s fade in, 1.0 s hold, 0.8 s fade out)
//    3. .complete (overlay removed by parent)
//

import SwiftUI

struct LaunchScreen: View {

    @Binding var phase: LaunchPhase

    @State private var blackOpacity: Double = 1.0
    @State private var whiteOpacity: Double = 0.0
    @State private var mbOpacity: Double = 1.0
    @State private var oracleOpacity: Double = 0.0

    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                    .opacity(blackOpacity)
                    .ignoresSafeArea()

                Color.white
                    .opacity(whiteOpacity)
                    .ignoresSafeArea()

                Image("mb_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 160, height: 160)
                    .opacity(mbOpacity)
                    .accessibilityHidden(true)

                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: min(geo.size.width, geo.size.height) * 0.85)
                    .opacity(oracleOpacity)
                    .accessibilityLabel("Oracle of Self")
            }
        }
        .ignoresSafeArea()
        .onAppear { startAnimation() }
        .onDisappear { animationTask?.cancel() }
    }

    private func startAnimation() {
        animationTask?.cancel()
        animationTask = Task {
            // Hold mb logo on black
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled else { return }

            // Cross-fade: mb out, black → white
            withAnimation(.easeInOut(duration: 0.6)) {
                mbOpacity = 0.0
                blackOpacity = 0.0
                whiteOpacity = 1.0
            }

            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            phase = .oracleSplash

            // Fade in Oracle logo
            withAnimation(.easeIn(duration: 0.7)) { oracleOpacity = 1.0 }

            // Hold the beautiful pose
            try? await Task.sleep(nanoseconds: 1_700_000_000)
            guard !Task.isCancelled else { return }

            // Fade out logo + white bg, revealing the app
            withAnimation(.easeOut(duration: 0.8)) {
                oracleOpacity = 0.0
                whiteOpacity = 0.0
            }

            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled else { return }
            phase = .complete
        }
    }
}

#Preview {
    LaunchScreen(phase: .constant(.mbLogo))
}
