import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct JobSubmitView: View {
    @Environment(\.presentationMode) var presentationMode
    var jobListing: JobListing
    @State private var price: String = ""  // Text field input for price
    @State private var proposalMessage: String = ""  // Text editor input for proposal message
    @State private var isSubmitting: Bool = false  // Loading state
    @State private var workerName: String = ""  // To store the worker's name
    
    var body: some View {
        VStack(spacing: 20) {  // Adjusted spacing for better layout
            Text("Submit a Proposal")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)  // Add top padding for better spacing
            
            TextField("Price (Fixed Rate)", text: $price)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color(.systemGray6))  // Use system background color for better visibility
                .cornerRadius(8)
            
            TextEditor(text: $proposalMessage)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .frame(height: 150)  // Set a fixed height for the text editor
            
            Button(action: submitProposal) {
                Text("Submit Proposal")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isSubmitting ? Color.gray : Color.blue)
                    .cornerRadius(8)
            }
            .disabled(isSubmitting || price.isEmpty || proposalMessage.isEmpty)
        }
        .padding()
        .background(Color.white)  // Set background to white for better contrast
        .cornerRadius(20)  // Optional: corner radius for better visual appeal
        .shadow(radius: 10)  // Add shadow for pop-up effect
        .navigationBarTitle("Submit Proposal", displayMode: .inline)
        .onAppear(perform: fetchWorkerName)  // Fetch the worker's name when the view appears
    }
    
    private func submitProposal() {
        guard let jobId = jobListing.id else { return }
        guard let priceValue = Double(price) else {
            print("Invalid price value")
            return
        }
        guard let workerId = Auth.auth().currentUser?.uid else {
            print("No authenticated user")
            return
        }
        
        let buyerId = jobListing.postedByUserId  // No need for guard let as it's not optional
        
        isSubmitting = true
        
        let db = Firestore.firestore()
        let proposal = Proposal(
            id: UUID().uuidString,
            jobId: jobId,
            price: priceValue,
            proposalMessage: proposalMessage,
            completionDate: Date().addingTimeInterval(60*60*24*7),  // Example: 1 week from now
            workerId: workerId,  // Use the authenticated user's ID
            workerName: workerName,  // Use the fetched worker name
            buyerId: buyerId  // Use the job's postedByUserId as buyerId
        )
        
        do {
            _ = try db.collection("proposals").addDocument(from: proposal)
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error submitting proposal: \(error.localizedDescription)")
        }
        
        isSubmitting = false
    }
    
    private func fetchWorkerName() {
        guard let workerId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(workerId).getDocument { document, error in
            if let document = document, document.exists {
                self.workerName = document.data()?["nickname"] as? String ?? "Unknown Worker"
            } else {
                print("Worker name could not be fetched: \(error?.localizedDescription ?? "Unknown error")")
                self.workerName = "Unknown Worker"
            }
        }
    }

}

