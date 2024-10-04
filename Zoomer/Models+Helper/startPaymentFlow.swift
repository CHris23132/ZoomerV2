import Stripe

func startPaymentFlow(amount: Int, currency: String, buyerId: String, jobId: String, cardParams: STPPaymentMethodCardParams) {
    createPaymentIntent(amount: amount, currency: currency, buyerId: buyerId, jobId: jobId) { clientSecret in
        guard let clientSecret = clientSecret else {
            print("Error: No client secret returned")
            return
        }

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: nil, metadata: nil)

        STPAPIClient.shared.confirmPaymentIntent(with: paymentIntentParams) { paymentIntent, error in
            if let error = error {
                print("Error confirming payment: \(error.localizedDescription)")
            } else if let paymentIntent = paymentIntent, paymentIntent.status == .requiresCapture {
                // Instead of accessing 'id' directly, print another accessible field or handle appropriately.
                print("Payment held in escrow with status: \(paymentIntent.status.rawValue)")
            }
        }
    }
}
