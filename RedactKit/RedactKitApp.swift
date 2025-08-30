//
//  RedactKitApp.swift
//  RedactKit
//
//  Created by Supachod Trakansirorut on 29/8/25.
//

import SwiftUI
import SwiftData

@main
struct RedactKitApp: App {
    @StateObject private var vm = ViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .modelContainer(for: Content.self)
                .environmentObject(vm)
        }
    }
}
