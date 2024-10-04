//
//  PaymentSetupView.swift
//  Zoomer
//
//  Created by Chris on 2024-09-19.
//

import SwiftUI
import Stripe

// View for setting up user payments with Stripe
struct PaymentSetupView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var cardParams = STPPaymentMethodCardParams() // Store card details
    @State private var isProcessing = false // Track if processing payment details
    @State private var paymentError: String? // Track errors during payment collection

    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Connect your Payment Information")
                .font(.title)
                .padding(.top, 20)

            // Stripe Payment Card Text Field
            StripePaymentCardTextField(cardParams: $cardParams)
                .padding(.horizontal)

            if let paymentError = paymentError {
                Text(paymentError)
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            Button(action: {
                // Validate and save card information
                savePaymentMethod()
            }) {
                Text(isProcessing ? "Processing..." : "Save Payment Information")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isProcessing ? Color.gray : Color.blue)
                    .cornerRadius(10)
            }
            .disabled(isProcessing) // Disable button when processing

            Spacer()
        }
        .padding()
    }

    // Function to save the user's payment method using Stripe
    private func savePaymentMethod() {
        isProcessing = true
        paymentError = nil // Clear previous errors

        // Create Payment Method Params with the card information
        let paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: nil, // Add billing details here if required
            metadata: nil
        )

        // Use Stripe API to create payment method (or call a Firebase function for it)
        STPAPIClient.shared.createPaymentMethod(with: paymentMethodParams) { paymentMethod, error in
            if let error = error {
                // Display any errors to the user
                paymentError = error.localizedDescription
                isProcessing = false
            } else if let paymentMethod = paymentMethod {
                // Payment method creation successful, now store this with your backend
                storePaymentMethod(paymentMethod: paymentMethod)
            }
        }
    }

    // Store payment method details with the backend (Firebase, for example)
    private func storePaymentMethod(paymentMethod: STPPaymentMethod) {
        // Simulate storing payment method, call your backend API or Firebase function
        print("Successfully created payment method: \(paymentMethod.stripeId)")

        // Example of sending the payment method to Firebase:
        // let functions = Functions.functions()
        // functions.httpsCallable("storePaymentMethod").call(["paymentMethodId": paymentMethod.stripeId])

        // Simulate completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isProcessing = false
            presentationMode.wrappedValue.dismiss() // Close the view
        }
    }
}

// Custom wrapper for Stripe's payment card text field
struct StripePaymentCardTextField: UIViewRepresentable {
    @Binding var cardParams: STPPaymentMethodCardParams

    func makeUIView(context: Context) -> STPPaymentCardTextField {
        let cardTextField = STPPaymentCardTextField()
        cardTextField.delegate = context.coordinator
        return cardTextField
    }

    func updateUIView(_ uiView: STPPaymentCardTextField, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(cardParams: $cardParams)
    }

    class Coordinator: NSObject, STPPaymentCardTextFieldDelegate {
        @Binding var cardParams: STPPaymentMethodCardParams

        init(cardParams: Binding<STPPaymentMethodCardParams>) {
            _cardParams = cardParams
        }

        func paymentCardTextFieldDidChange(_ textField: STPPaymentCardTextField) {
            // Update the card parameters when the text field changes
            cardParams.number = textField.cardNumber
            cardParams.expMonth = textField.expirationMonth as NSNumber
            cardParams.expYear = textField.expirationYear as NSNumber
            cardParams.cvc = textField.cvc
        }
    }
}
