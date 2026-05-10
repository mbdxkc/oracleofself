//
//  Colors.swift
//  Oracle of Self
//
//  App color scheme - blueish silver/slate.
//

import SwiftUI

extension Color {
    /// Primary accent color - blueish silver
    static let accent = Color(red: 0.55, green: 0.65, blue: 0.78)

    /// Secondary accent - lighter variant
    static let accentLight = Color(red: 0.7, green: 0.78, blue: 0.88)

    /// Tertiary accent - darker variant
    static let accentDark = Color(red: 0.4, green: 0.5, blue: 0.65)
}

extension ShapeStyle where Self == Color {
    static var accent: Color { .accent }
    static var accentLight: Color { .accentLight }
    static var accentDark: Color { .accentDark }
}
