//
//  PaymentService.swift
// Paypal
//  Zoomer
//
//  Created by Christopher Walsh on 2024-09-08.
//

import Foundation

class PayPalPaymentService {
    
    private let clientId: String
    private let secretKey: String
    private let isSandbox: Bool
    
    // Initialize the service with client credentials
    init(clientId: String, secretKey: String, isSandbox: Bool = true) {
        self.clientId = clientId
        self.secretKey = secretKey
        self.isSandbox = isSandbox
    }
    
    // Base URL based on environment (Sandbox or Live)
    private var baseURL: String {
        return isSandbox ? "https://api.sandbox.paypal.com" : "https://api.paypal.com"
    }
    
    // Function to get PayPal access token
    private func getPayPalAccessToken(completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/v1/oauth2/token") else {
            completion(nil)
            return
        }

        let credentials = "\(clientId):\(secretKey)"
        guard let encodedCredentials = credentials.data(using: .utf8)?.base64EncodedString() else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(encodedCredentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "grant_type=client_credentials".data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to get access token: \(error?.localizedDescription ?? "No data")")
                completion(nil)
                return
            }

            do {
                let tokenResponse = try JSONDecoder().decode(PayPalAccessToken.self, from: data)
                completion(tokenResponse.access_token)
            } catch {
                print("Failed to decode access token: \(error)")
                completion(nil)
            }
        }
        task.resume()
    }
    
    // Function to create a PayPal order (authorize payment)
    func createPayPalOrder(amount: String, currency: String, completion: @escaping (String?) -> Void) {
        getPayPalAccessToken { accessToken in
            guard let accessToken = accessToken else {
                completion(nil)
                return
            }
            
            guard let url = URL(string: "\(self.baseURL)/v2/checkout/orders") else {
                completion(nil)
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let orderData: [String: Any] = [
                "intent": "AUTHORIZE",
                "purchase_units": [
                    [
                        "amount": [
                            "currency_code": currency,
                            "value": amount
                        ]
                    ]
                ]
            ]
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: orderData, options: [])
                request.httpBody = jsonData
            } catch {
                print("Error creating order data: \(error)")
                completion(nil)
                return
            }

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    print("Failed to create order: \(error?.localizedDescription ?? "No data")")
                    completion(nil)
                    return
                }

                do {
                    let orderResponse = try JSONDecoder().decode(PayPalOrderResponse.self, from: data)
                    completion(orderResponse.id) // Return order ID
                } catch {
                    print("Failed to decode order response: \(error)")
                    completion(nil)
                }
            }

            task.resume()
        }
    }

    // Function to capture the authorized payment after verification
    func capturePayPalPayment(orderID: String, completion: @escaping (Bool) -> Void) {
        getPayPalAccessToken { accessToken in
            guard let accessToken = accessToken else {
                completion(false)
                return
            }

            guard let url = URL(string: "\(self.baseURL)/v2/checkout/orders/\(orderID)/capture") else {
                completion(false)
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                    print("Failed to capture payment: \(error?.localizedDescription ?? "No data")")
                    completion(false)
                    return
                }

                print("Payment captured successfully")
                completion(true)
            }

            task.resume()
        }
    }

    // Function to send payout to seller after capturing payment
    func sendPayPalPayout(sellerEmail: String, amount: String, completion: @escaping (Bool) -> Void) {
        getPayPalAccessToken { accessToken in
            guard let accessToken = accessToken else {
                completion(false)
                return
            }

            guard let url = URL(string: "\(self.baseURL)/v1/payments/payouts") else {
                completion(false)
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let payoutData: [String: Any] = [
                "sender_batch_header": [
                    "sender_batch_id": UUID().uuidString,
                    "email_subject": "You have received a payout!"
                ],
                "items": [
                    [
                        "recipient_type": "EMAIL",
                        "amount": [
                            "value": amount,
                            "currency": "USD"
                        ],
                        "receiver": sellerEmail,
                        "note": "Thanks for your service!",
                        "sender_item_id": UUID().uuidString
                    ]
                ]
            ]
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: payoutData, options: [])
                request.httpBody = jsonData
            } catch {
                print("Error creating payout data: \(error)")
                completion(false)
                return
            }

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                    print("Failed to send payout: \(error?.localizedDescription ?? "No data")")
                    completion(false)
                    return
                }

                print("Payout sent successfully")
                completion(true)
            }

            task.resume()
        }
    }
}

// PayPalAccessToken struct to decode the token response
struct PayPalAccessToken: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
}

// PayPalOrderResponse struct to decode the order response
struct PayPalOrderResponse: Codable {
    let id: String
    let status: String
}
