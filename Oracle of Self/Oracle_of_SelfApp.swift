//
//  Oracle_of_SelfApp.swift
//  Oracle of Self
//
//  Created by valdez campos on 5/10/26.
//

import SwiftUI

@main
struct Oracle_of_SelfApp: App {

    @State private var launchPhase: LaunchPhase = .mbLogo
    @State private var showLaunchScreen: Bool = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()

                if showLaunchScreen {
                    LaunchScreen(phase: $launchPhase)
                        .zIndex(1)
                }
            }
            .onChange(of: launchPhase) { _, newPhase in
                if newPhase == .complete {
                    showLaunchScreen = false
                }
            }
        }
    }
}
