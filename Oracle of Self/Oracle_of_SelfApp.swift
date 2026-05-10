//
//  Oracle_of_SelfApp.swift
//  Oracle of Self
//
//  Created by valdez campos on 5/10/26.
//

import SwiftUI

@main
struct Oracle_of_SelfApp: App {

    @State private var splashBgOpacity: Double = 1.0
    @State private var splashLogoOpacity: Double = 0.0
    @State private var showSplash: Bool = true

    private let fadeDuration: Double = 1.8
    private let holdSeconds: Double = 2.0

    var body: some Scene {
        WindowGroup {
            ZStack {
                // ContentView paints its own black bg + 0.05 watermark in
                // each tab. The splash overlay below reuses `LogoWatermark`
                // with the same modifiers, so the splash logo and the
                // watermark sit in the same pixel position.
                ContentView()

                if showSplash {
                    SplashScreen(
                        backgroundOpacity: splashBgOpacity,
                        logoOpacity: splashLogoOpacity,
                        duration: fadeDuration
                    )
                    .zIndex(1)
                }
            }
            .task { await runSplash() }
        }
    }

    @MainActor
    private func runSplash() async {
        try? await Task.sleep(nanoseconds: 80_000_000)

        // Logo fades in over the already-opaque black bg
        splashLogoOpacity = 0.25

        let waitNs = UInt64((fadeDuration + holdSeconds) * 1_000_000_000)
        try? await Task.sleep(nanoseconds: waitNs)

        // Fade out: cover and splash logo drop together. Underneath, the
        // permanent watermark at 0.05 is already sitting in the same spot,
        // so the apparent transition is just opacity going 0.25 → 0.05.
        splashBgOpacity = 0.0
        splashLogoOpacity = 0.0

        try? await Task.sleep(nanoseconds: UInt64(fadeDuration * 1_000_000_000))
        showSplash = false
    }
}
