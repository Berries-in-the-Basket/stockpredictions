//
//  StockPredictionsApp.swift
//  StockPredictions
//
//  Created by Mariusz Smoliński on 08.04.25.
//

import SwiftUI

@main
struct StockPredictionsApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
