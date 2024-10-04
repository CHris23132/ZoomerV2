//
//  getJobListing.swift
//  Zoomer
//
//  Created by Christopher Walsh on 2024-08-18.
//

import FirebaseFirestore

func getJobListing(byId id: String, completion: @escaping (JobListing?) -> Void) {
    let db = Firestore.firestore()
    let docRef = db.collection("job_listings").document(id)
    
    docRef.getDocument { (document, error) in
        if let document = document, document.exists {
            do {
                let jobListing = try document.data(as: JobListing.self)
                completion(jobListing)
            } catch {
                print("Error decoding job listing: \(error)")
                completion(nil)
            }
        } else {
            print("Document does not exist")
            completion(nil)
        }
    }
}
