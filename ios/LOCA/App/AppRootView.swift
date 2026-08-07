//
//  AppRootView.swift
//  LOCA
//
//  P1A — Two-tab root replacing the eye-icon fullScreenCover flow.
//  Habits and Life are now first-class peers with equal navigation weight.
//

import SwiftUI

struct AppRootView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Habits", systemImage: "checkmark.circle.fill")
                }

            LifeHomeView()
                .tabItem {
                    Label("Life", systemImage: "binoculars")
                }
        }
    }
}

#Preview {
    AppRootView()
}
