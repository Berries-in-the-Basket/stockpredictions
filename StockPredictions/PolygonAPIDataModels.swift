//
//  PolygonAPIDataModels.swift
//  StockPredictions
//
//  Created by Mariusz Smoliński on 10.04.25.
//

import Foundation

//single day's aggregate data for a ticker.
struct AggregateResult: Codable {
    let v: Int?       // Volume
    let o: Double?    // Open price
    let c: Double?    // Close price
    let h: Double?    // High price
    let l: Double?    // Low price
    let t: Int?       // Timestamp (milliseconds since epoch)
    let n: Int?       // Number of transactions
}

struct PolygonAggregatesResponse: Codable {
    let ticker: String?
    let status: String?
    let queryCount: Int?
    let resultsCount: Int?
    let adjusted: Bool?
    let results: [AggregateResult]?
}
