import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Stripe
import FirebaseFunctions

struct ProposalItemView: View {
    var proposal: Proposal
    var jobListing: JobListing
    @State private var userId: String? = Auth.auth().currentUser?.uid  // Get the current user's ID
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Text(proposal.workerName)
                    .font(.headline)
                    .foregroundColor(.black)

                Text(proposal.proposalMessage)
                    .font(.body)
                    .foregroundColor(.gray)

                HStack {
                    Text("Price: \(proposal.price, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text("Completion Date: \(proposal.completionDate, formatter: dateFormatter)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            if jobListing.postedByUserId == userId {
                HStack {
                    Button(action: {
                        approveProposal(proposalId: proposal.id ?? "", jobId: jobListing.id ?? "", proposal: proposal)
                    }) {
                        Text("Approve")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()

                    Button(action: {
                        declineProposal(proposalId: proposal.id ?? "")
                    }) {
                        Text("Deny")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 10)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Proposal Management"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func approveProposal(proposalId: String, jobId: String, proposal: Proposal) {
        let db = Firestore.firestore()

        // Step 1: Update the job status to "In Progress"
        db.collection("job_listings").document(jobId).updateData(["status": "In Progress"]) { error in
            if let error = error {
                alertMessage = "Error approving proposal: \(error.localizedDescription)"
                showAlert = true
                return
            }

            // Step 2: Trigger Stripe Payment Intent
            createPaymentIntent(amount: Int(proposal.price * 100), currency: "usd", buyerId: jobListing.postedByUserId ?? "", jobId: jobListing.id ?? "") { clientSecret in
                if let clientSecret = clientSecret {
                    redirectToStripePayment(clientSecret: clientSecret)
                } else {
                    alertMessage = "Error creating payment intent."
                    showAlert = true
                }
            }
        }
    }
 

    private func redirectToStripePayment(clientSecret: String) {
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242" // Test card number
        cardParams.expMonth = 12
        cardParams.expYear = 2024
        cardParams.cvc = "123"
        
        let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: nil, metadata: nil)
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
        paymentIntentParams.paymentMethodParams = paymentMethodParams
        
        STPAPIClient.shared.confirmPaymentIntent(with: paymentIntentParams) { paymentIntent, error in
            if let error = error {
                print("Error confirming payment: \(error.localizedDescription)")
            } else if let paymentIntent = paymentIntent {
                handlePaymentIntentStatus(paymentIntent)
            } else {
                print("Unexpected error: No paymentIntent or error provided")
            }
        }
    }

    private func capturePaymentIntent(paymentIntentId: String, completion: @escaping (Bool, Error?) -> Void) {
        let functions = Functions.functions()
        functions.httpsCallable("capturePayment").call(["paymentIntentId": paymentIntentId]) { result, error in
            if let error = error {
                print("Error capturing PaymentIntent: \(error.localizedDescription)")
                completion(false, error)
                return
            }
            completion(true, nil)
        }
    }
    
    private func handlePaymentIntentStatus(_ paymentIntent: STPPaymentIntent) {
        switch paymentIntent.status {
        case .requiresAction:
            print("Payment requires additional action")
            handleAuthentication(for: paymentIntent)
            
        case .requiresCapture:
            print("Payment requires capture")
             let paymentIntentId = paymentIntent.stripeId
            capturePaymentIntent(paymentIntentId: paymentIntentId) { success, error in
                if success {
                    print("Payment successfully captured")
                } else {
                    print("Failed to capture payment: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
            
        case .succeeded:
            print("Payment succeeded")
        case .canceled:
            print("Payment canceled")
        case .processing:
            print("Payment is processing")
        case .requiresPaymentMethod:
            print("Payment requires a new payment method")
        case .requiresSource:
            print("Payment requires a source")
        case .requiresConfirmation:
            print("Payment requires confirmation")
            confirmPaymentIntent(paymentIntent.clientSecret)
        case .requiresSourceAction:
            print("Payment requires source action")
            handleAuthentication(for: paymentIntent)
        @unknown default:
            print("Unknown payment intent status")
        }
    }
    
    func confirmPaymentIntent(_ clientSecret: String) {
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
        STPAPIClient.shared.confirmPaymentIntent(with: paymentIntentParams) { paymentIntent, error in
            if let error = error {
                print("Error confirming payment: \(error.localizedDescription)")
            } else {
                print("Payment confirmed successfully")
            }
        }
    }

    func handleAuthentication(for paymentIntent: STPPaymentIntent) { }


    private func declineProposal(proposalId: String) {
        let db = Firestore.firestore()
        db.collection("proposals").document(proposalId).delete { error in
            if let error = error {
                alertMessage = "Error declining proposal: \(error.localizedDescription)"
            } else {
                alertMessage = "Proposal declined successfully."
            }
            showAlert = true
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}
