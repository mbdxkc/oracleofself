//
//  LaunchPhase.swift
//  Oracle of Self
//
//  State machine for the animated splash:
//    1. .mbLogo        — mediaBrilliance branding on black
//    2. .oracleSplash  — Oracle of Self logo full-screen, fades into the app
//    3. .complete      — splash dismissed, ContentView visible
//

enum LaunchPhase {
    case mbLogo
    case oracleSplash
    case complete
}
