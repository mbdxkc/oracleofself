//
//  SplashScreen.swift
//  Oracle of Self
//
//  Black cover + the same `LogoWatermark` image at a higher opacity. Lives
//  at the App root so the splash logo and the permanent watermark share the
//  exact same parent frame — the image never shifts between them.
//

import SwiftUI

struct SplashScreen: View {
    let backgroundOpacity: Double
    let logoOpacity: Double
    let duration: Double

    var body: some View {
        ZStack {
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: duration), value: backgroundOpacity)

            LogoWatermark(opacity: logoOpacity)
                .animation(.easeInOut(duration: duration), value: logoOpacity)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
