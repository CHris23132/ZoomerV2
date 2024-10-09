import Foundation

class StripeService {
    // Use the correct Cloud Run URL
    let firebaseFunctionsURL = "https://createpaymentintent-78300117871.us-central1.run.app"

    // MARK: - Start Stripe Connect Onboarding
    func createStripeAccountLink(for userId: String, completion: @escaping (URL?) -> Void) {
        guard let url = URL(string: firebaseFunctionsURL) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = ["userId": userId]
        do {
            let jsonBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            request.httpBody = jsonBody
        } catch {
            print("Error serializing request body: \(error)")
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error making request: \(error?.localizedDescription ?? "No data")")
                completion(nil)
                return
            }

            do {
                if let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let urlString = responseJSON["url"] as? String, let url = URL(string: urlString) {
                    completion(url)
                } else {
                    completion(nil)
                }
            } catch {
                print("Error parsing response: \(error)")
                completion(nil)
            }
        }

        task.resume()
    }
}
