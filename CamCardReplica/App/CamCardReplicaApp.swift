//
//  CamCardReplicaApp.swift
//  CamCardReplica
//
//  Created by Makoto Wu on 2026/10/29.
//

import SwiftUI
import SwiftData

@main
struct CamCardReplicaApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: BusinessCard.self)

            if ProcessInfo.processInfo.arguments.contains("-ResetUITestStore") {
                let context = ModelContext(modelContainer)
                let cards = try context.fetch(FetchDescriptor<BusinessCard>())
                for card in cards {
                    context.delete(card)
                }
                try context.save()
                try CardImageStore.live.removeAllImages()
            }
        } catch {
            fatalError("Unable to initialize the local card store: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .modelContainer(modelContainer)
    }
}
