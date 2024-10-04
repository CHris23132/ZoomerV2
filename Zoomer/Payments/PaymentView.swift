import SwiftUI
import Stripe

struct PaymentView: View {
    @State private var cardParams = STPPaymentMethodCardParams()

    var body: some View {
        VStack {
            StripeCardFieldWrapper()  // Use a wrapper for Stripe card text field

            Button(action: {
                startPaymentFlow(amount: 5000, currency: "usd", buyerId: "buyer123", jobId: "job123", cardParams: cardParams)
            }) {
                Text("Pay $50.00")
            }
        }
        .padding()
    }
}

struct StripeCardFieldWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> STPPaymentCardTextField {
        return STPPaymentCardTextField()
    }

    func updateUIView(_ uiView: STPPaymentCardTextField, context: Context) {}
}
