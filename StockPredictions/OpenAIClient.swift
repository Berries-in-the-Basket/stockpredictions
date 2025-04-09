//
//  OpenAIClient.swift
//  StockPredictions
//
//  Created by Mariusz Smoliński on 08.04.25.
//

import Foundation
import Alamofire

func callChatOpenAIAPI(prompt: String) async throws -> ChatResponse {
    let url = "https://api.openai.com/v1/chat/completions"

    let headers: HTTPHeaders = [
        "Content-Type": "application/json",
        "Authorization": "Bearer \(APIKeys.openAIAPIKey)"
    ]
    
    let messages = [
        ChatMessage(role: "system", content: "You are a helpful general knowledge expert. You reply with brief, to-the-point answers."),
        ChatMessage(role: "user", content: prompt)
    ]
    
    let chatRequest = ChatRequest(model: "gpt-4o", messages: messages, max_completion_tokens: 50)
    
    // request using Alamofire
    let dataTask = AF.request(
        url,
        method: .post,
        parameters: chatRequest,
        encoder: JSONParameterEncoder.default,
        headers: headers
    )
    .validate()
    .serializingDecodable(ChatResponse.self)
    
    let result = try await dataTask.value
    return result
}

