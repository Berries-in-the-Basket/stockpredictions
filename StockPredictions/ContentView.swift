//
//  ContentView.swift
//  StockPredictions
//
//  Created by Mariusz Smoliński on 08.04.25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    @State private var prompt = ""
    @State private var responseText = "Enter a prompt and press Send"
    @State private var isLoading = false
    
    @State private var ticker = ""
    @State private var tickers: [String] = []
    
    var body: some View {
        VStack(spacing: 20) {
            // Header or instruction text.
            Text("Enter a Stock Ticker:")
                .font(.headline)
            
            // HStack containing the text field and an add button.
            HStack {
                TextField("Ticker Symbol", text: $ticker)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical, 8)
                
                // Button to add the entered ticker to the list.
                Button(action: {
                    guard !ticker.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    // Optionally, convert the ticker to uppercase
                    tickers.append(ticker.uppercased())
                    ticker = ""
                }) {
                    Text("Add")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            // Label for the tickers display area.
            Text("Entered Tickers:")
                .font(.headline)
            
            // A scrollable text area that displays all the tickers.
            ScrollView {
                HStack(alignment: .center, spacing: 5) {
                    ForEach(tickers, id: \.self) { ticker in
                        Text(ticker)
                            .padding(.vertical, 4)
                    }
                }
                .padding(5)
            }
            .frame(maxHeight: 200)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // The Generate Report button.
            Button(action: {
                // Insert your report generation logic here.
                print("Generating report for tickers: \(tickers)")
            }) {
                Text("Generate Report")
                    .foregroundColor(.white)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
    }
    
    
    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
