//
//  ContentView.swift
//  Oracle of Self
//
//  Root view. Two-tab layout: Oracle (quiz) and Insights (saved readings).
//

import SwiftUI

struct ContentView: View {
    @State private var controller = OracleController()
    @State private var diary = DiaryController()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            OracleView(controller: controller, diary: diary)
                .tabItem {
                    Label("Oracle", systemImage: "sparkles")
                }
                .tag(0)

            InsightsView(diary: diary, onTryAgain: tryAgain)
                .tabItem {
                    Label("Insights", systemImage: "book.closed")
                }
                .tag(1)
        }
        .tint(Color.accent)
    }

    private func tryAgain(question: String) {
        controller.start(question: question)
        selectedTab = 0
    }
}

#Preview {
    ContentView()
}
