import FirebaseFirestore

class VoteManager {
    
    // Listen for votes related to a specific job
    static func listenForJobVotes(jobId: String) {
        let db = Firestore.firestore()

        // Real-time listener for votes related to the job
        db.collection("verification_votes")
            .whereField("jobId", isEqualTo: jobId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error listening for votes: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }
                
                // Extract vote information
                let votes = documents.compactMap { $0.data()["vote"] as? String }

                print("Total votes for job \(jobId): \(votes.count)")

                // If 3 or more votes exist, process them
//                if votes.count >= 3 {
                if votes.count >= 2 {
                    processVotes(votes: votes, jobId: jobId)
                }
            }
    }
    
    // Process votes and decide the job's outcome
    static private func processVotes(votes: [String], jobId: String) {
        // Count the number of approve and deny votes
        let approveVotes = votes.filter { $0 == "approve" }.count
        let denyVotes = votes.filter { $0 == "deny" }.count

        print("Approve votes: \(approveVotes), Deny votes: \(denyVotes) for job \(jobId)")

        // If 2 or more votes are approve, mark job as complete
        if approveVotes >= 2 {
            print("Job \(jobId) has 2 or more approve votes. Updating status to 'Completed'.")
            updateJobStatus(jobId: jobId, newStatus: "Completed")
        }
        // If 2 or more votes are deny, mark job as rejected
        else if denyVotes >= 2 {
            print("Job \(jobId) has 2 or more deny votes. Updating status to 'Rejected'.")
            updateJobStatus(jobId: jobId, newStatus: "Rejected")
        }
        // If less than 2 votes for both, do nothing (could be a tie, still waiting on more votes)
        else {
            print("Not enough decisive votes for job \(jobId) yet.")
        }
    }
    
    // Update the status of the job in Firestore
    static private func updateJobStatus(jobId: String, newStatus: String) {
        let db = Firestore.firestore()

        db.collection("job_listings").document(jobId).updateData([
            "status": newStatus
        ]) { error in
            if let error = error {
                print("Error updating job status to \(newStatus): \(error.localizedDescription)")
            } else {
                print("Job status updated to \(newStatus) successfully.")
            }
        }
    }
}
