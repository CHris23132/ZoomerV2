import FirebaseFunctions

let functions = Functions.functions()

func createPaymentIntent(amount: Int, currency: String, buyerId: String, jobId: String, completion: @escaping (String?) -> Void) {
    let data: [String: Any] = [
        "amount": amount,
        "currency": currency,
        "buyerId": buyerId,
        "jobId": jobId
    ]

    functions.httpsCallable("createPaymentIntent").call(data) { result, error in
        if let error = error {
            print("Error: \(error.localizedDescription)")
            completion(nil)
            return
        }

        if let clientSecret = (result?.data as? [String: Any])?["clientSecret"] as? String {
            completion(clientSecret)
        } else {
            completion(nil)
        }
    }
}
