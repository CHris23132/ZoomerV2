// In ActiveJobsListView.swift
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ActiveJobsListView: View {
    @State private var activeJobs: [JobListing] = []
    @State private var isLoading = true
    @State private var selectedJob: JobListing?
    @State private var showCompletionView: Bool = false

    var body: some View {
        List {
            if isLoading {
                Text("Loading active jobs...")
                    .font(.headline)
                    .padding()
            } else if activeJobs.isEmpty {
                Text("No active jobs.")
                    .font(.headline)
                    .padding()
            } else {
                ForEach(activeJobs) { job in
                    ContractItemView(
                        status: job.status,
                        name: job.title,
                        rating: job.rating ?? 0.0,
                        description: job.description,
                        onComplete: {
                            self.selectedJob = job
                            self.showCompletionView.toggle()
                        }
                    )
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color.clear)
        .listStyle(PlainListStyle())
        .onAppear(perform: fetchActiveJobs)
        .sheet(item: $selectedJob) { job in
            JobCompletionView(job: job)
        }
    }

    private func fetchActiveJobs() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: User is not logged in.")
            return
        }

        isLoading = true
        let db = Firestore.firestore()

        db.collection("job_listings")
            .whereField("postedByUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: "In Progress")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching active jobs: \(error.localizedDescription)")
                    isLoading = false
                    return
                }

                self.activeJobs = snapshot?.documents.compactMap { document in
                    try? document.data(as: JobListing.self)
                } ?? []

                isLoading = false
            }
    }
}
