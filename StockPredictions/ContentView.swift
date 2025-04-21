//
//  ContentView.swift
//  StockPredictions
//
//  Created by Mariusz Smoliński on 08.04.25.
//

import SwiftUI
import CoreData
import Alamofire

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
    
    @State private var stockData: [String: PolygonAggregatesResponse] = [:]
    @State private var errorMessage: String?
    
    @State private var stockReport: String = ""
    
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
                VStack {
                    Text("Entered Tickers:")
                        .font(.headline)
                    if tickers != [] {
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
                    .frame(width: 250, height: 80)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
          
            
            // The Generate Report button.
            Button(action: {
                // Insert your report generation logic here.
                print("Generating report for tickers: \(tickers)")
                isLoading = true
                Task {
                    do {
                        let data = try await fetchStockData(for: tickers)
                        let jsonData = try JSONEncoder().encode(data)
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            let openAIResponse = try await callChatOpenAIAPI(prompt: jsonString)
                            if let choice = openAIResponse.choices.first{
                                // Update the UI on the main thread.
                                await MainActor.run {
                                    stockReport = choice.message.content
                                    //                                add here update UI for the OpenAI report
                                    isLoading = false
                                }
                            } else{
                                stockReport = "No response received"
                            }
                        } else{
                            await MainActor.run {
                                stockReport = "Unable to decode response."
                                isLoading = false
                            }
                        }
                    } catch {
                        await MainActor.run {
                            errorMessage = error.localizedDescription
                            stockReport = errorMessage ?? ""
                            isLoading = false
                        }
                    }
                }
            }) {
                Text(isLoading ? "Loading..." : "Generate Report")
                    .foregroundColor(.white)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            
            // Display the stock report
            Text("Stock Report:")
                .font(.headline)
            if stockReport != "" {
                ScrollView {
                    Text(stockReport)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                }
                //            .frame(maxHeight: 300)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
            
            
            Spacer()
        }
        .padding()
    }
    
    func fetchStockData(for tickers: [String]) async throws -> [String: PolygonAggregatesResponse] {
        var responses = [String: PolygonAggregatesResponse]()
        let polygonApiKey = APIKeys.polygonIoAPIKey  // Replace with your actual Polygon.io API key
        
        // Date formatter for the required "yyyy-MM-dd" format.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Compute today's date and the date 3 days ago.
        let toDate = dateFormatter.string(from: Date())
        guard let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date()) else {
            throw NSError(domain: "DateError",
                          code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Could not compute 7 days ago date"])
        }
        let fromDate = dateFormatter.string(from: sevenDaysAgo)
        
        // Loop through each ticker to fetch its aggregated data.
        for ticker in tickers {
            // Build the API URL for each ticker.
            let urlString = "https://api.polygon.io/v2/aggs/ticker/\(ticker)/range/1/day/\(fromDate)/\(toDate)?adjusted=true&sort=asc&limit=120&apiKey=\(polygonApiKey)"
            guard let url = URL(string: urlString) else {
                print("Invalid URL for ticker: \(ticker)")
                continue
            }
            
            do {
                // Request using Alamofire and decode the response into PolygonAggregatesResponse.
                let response = AF.request(url, method: .get)
                    .validate()
                    .serializingDecodable(PolygonAggregatesResponse.self)
                let result = try await response.value
                responses[ticker] = result
            } catch {
                print("Error fetching data for \(ticker): \(error.localizedDescription)")
            }
        }
        print(responses)
        
        return responses
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
