import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProposalView: View {
    var jobListing: JobListing
    @State private var proposals: [Proposal] = []
    @State private var userId: String? = Auth.auth().currentUser?.uid  // Get the current user's ID
    
    var body: some View {
        VStack {
            if proposals.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No proposals yet.")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding()
            } else {
                List(proposals) { proposal in
                    ProposalItemView(proposal: proposal, jobListing: jobListing)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }
                .listStyle(PlainListStyle())
            }
        }
        .background(Color(.systemGray6).ignoresSafeArea())
        .navigationBarTitle("Proposals")
        .onAppear(perform: loadProposals)
    }
    
    private func loadProposals() {
        guard let jobId = jobListing.id else {
            print("Error: Job ID is nil")
            return
        }
        
        let db = Firestore.firestore()
        
        // Load proposals for jobs that are still in "Pending" or "Open"
        if jobListing.status == "Pending" || jobListing.status == "Open" {
            db.collection("proposals")
                .whereField("jobId", isEqualTo: jobId)
                .getDocuments { (snapshot, error) in
                    if let error = error {
                        print("Error loading proposals: \(error.localizedDescription)")
                        return
                    }
                    
                    self.proposals = snapshot?.documents.compactMap { document in
                        do {
                            let proposal = try document.data(as: Proposal.self)
                            return proposal
                        } catch {
                            print("Error decoding proposal: \(error.localizedDescription)")
                            return nil
                        }
                    } ?? []
                }
        } else {
            self.proposals = []  // Clear proposals if the job is in progress or completed
        }
    }
    
    // Submit a new proposal and include buyerId from the job listing
    // Ensure all critical fields are included when submitting the proposal
    private func submitProposal(proposalMessage: String, price: Int) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: User not logged in.")
            return
        }
        guard let jobId = jobListing.id else {
            print("Error: Job ID is nil.")
            return
        }
        
        let db = Firestore.firestore()
        
        // Fetch the job listing to get buyerId
        db.collection("job_listings").document(jobId).getDocument { (document, error) in
            if let error = error {
                print("Error fetching job listing: \(error.localizedDescription)")
                return
            }
            
            guard let jobData = document?.data(), let buyerId = jobData["postedByUserId"] as? String else {
                print("Error: Job or buyerId not found.")
                return
            }
            
            // Create the proposal document with all relevant fields
            let proposalRef = db.collection("proposals").document()
            let proposalData: [String: Any] = [
                "proposalId": proposalRef.documentID,
                "jobId": jobId,
                "buyerId": buyerId,        // Buyer ID from job listing
                "workerId": userId,         // Worker (current user submitting the proposal)
                "price": price,             // Price in cents
                "proposalMessage": proposalMessage,
                "status": "submitted",
                "timestamp": FieldValue.serverTimestamp()
            ]
            
            proposalRef.setData(proposalData) { error in
                if let error = error {
                    print("Error creating proposal: \(error.localizedDescription)")
                } else {
                    print("Proposal submitted successfully.")
                }
            }
        }
    }
}
