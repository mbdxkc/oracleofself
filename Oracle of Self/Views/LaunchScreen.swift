//
//  LaunchScreen.swift
//  Oracle of Self
//
//  Two-phase animated splash:
//    1. mediaBrilliance logo on black (~0.8 s hold, 0.6 s cross-fade)
//    2. Oracle of Self logo on icon-bg gray (1.8 s slow fade-in to 0.5 opacity,
//       1.0 s hold, 1.0 s fade out into the app)
//    3. .complete (overlay removed by parent)
//
//  Total ~5.7 s gives the rest of the app time to settle before reveal.
//

import SwiftUI

private let iconBackground = Color(red: 242/255, green: 242/255, blue: 242/255)

struct LaunchScreen: View {

    @Binding var phase: LaunchPhase

    @State private var blackOpacity: Double = 1.0
    @State private var iconBgOpacity: Double = 0.0
    @State private var mbOpacity: Double = 1.0
    @State private var oracleOpacity: Double = 0.0

    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                    .opacity(blackOpacity)
                    .ignoresSafeArea()

                iconBackground
                    .opacity(iconBgOpacity)
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
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled else { return }

            // Cross-fade: mb out, black → icon bg
            withAnimation(.easeInOut(duration: 0.6)) {
                mbOpacity = 0.0
                blackOpacity = 0.0
                iconBgOpacity = 1.0
            }

            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            phase = .oracleSplash

            // Slow fade-in of Oracle logo to half-opacity (ghostly, not full)
            withAnimation(.easeIn(duration: 1.8)) { oracleOpacity = 0.5 }

            // Hold the half-opacity pose; gives the app behind time to settle
            try? await Task.sleep(nanoseconds: 2_800_000_000)
            guard !Task.isCancelled else { return }

            // Fade logo + icon bg out, revealing the app
            withAnimation(.easeOut(duration: 1.0)) {
                oracleOpacity = 0.0
                iconBgOpacity = 0.0
            }

            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            phase = .complete
        }
    }
}

#Preview {
    LaunchScreen(phase: .constant(.mbLogo))
}
