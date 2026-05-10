//
//  LogoWatermark.swift
//  Oracle of Self
//
//  Single source of truth for the Logo image's size and position. Used by
//  both the permanent app-bg watermark (low opacity) and the splash overlay
//  (higher opacity) so the image never shifts between them.
//
//  GeometryReader + explicit frame + .clipped() prevents the image's
//  fill-mode overflow from expanding the parent's layout bounds, which
//  was causing siblings (text, fields) to render wider than the screen.
//

import SwiftUI

struct LogoWatermark: View {
    let opacity: Double

    var body: some View {
        GeometryReader { geo in
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .opacity(opacity)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
