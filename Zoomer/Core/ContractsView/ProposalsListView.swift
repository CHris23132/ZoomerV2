import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProposalsListView: View {
    @State private var proposals: [Proposal] = []
    @State private var jobListings: [JobListing] = []
    @State private var isLoading = true

    var body: some View {
        List {
            if isLoading {
                Text("Loading proposals...")
                    .font(.headline)
                    .padding()
            } else if proposals.isEmpty {
                Text("No proposals yet.")
                    .font(.headline)
                    .padding()
            } else {
                ForEach(proposals) { proposal in
                    if let jobListing = jobListings.first(where: { $0.id == proposal.jobId }) {
                        ProposalItemView(proposal: proposal, jobListing: jobListing)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .background(Color(.systemGray6).ignoresSafeArea())
        .onAppear(perform: fetchProposals)
    }

    private func fetchProposals() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: User is not logged in.")
            return
        }

        isLoading = true
        let db = Firestore.firestore()

        // Fetch all job listings posted by the current user
        db.collection("job_listings")
            .whereField("postedByUserId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching job listings: \(error.localizedDescription)")
                    isLoading = false
                    return
                }

                // Filter out jobs with a status of "In Progress" or "Completed"
                self.jobListings = snapshot?.documents.compactMap { document in
                    let job = try? document.data(as: JobListing.self)
                    if let job = job, job.status != "In Progress" && job.status != "Completed" {
                        return job
                    }
                    return nil
                } ?? []

                let jobIds = self.jobListings.compactMap { $0.id }

                guard !jobIds.isEmpty else {
                    print("No job listings found for the current user.")
                    isLoading = false
                    return
                }

                // Fetch proposals for the user's job listings
                db.collection("proposals")
                    .whereField("jobId", in: jobIds)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            print("Error fetching proposals: \(error.localizedDescription)")
                            isLoading = false
                            return
                        }

                        self.proposals = snapshot?.documents.compactMap { try? $0.data(as: Proposal.self) } ?? []
                        isLoading = false
                    }
            }
    }
}
