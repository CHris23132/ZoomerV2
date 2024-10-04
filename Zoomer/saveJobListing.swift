//
//  saveJobListing.swift
//  Zoomer
//
//  Created by Christopher Walsh on 2024-08-18.
//

import FirebaseFirestore

func saveJobListing(_ jobListing: JobListing) {
    let db = Firestore.firestore()
    
    do {
        let _ = try db.collection("job_listings").document(jobListing.id ?? UUID().uuidString).setData(from: jobListing)
    } catch let error {
        print("Error writing job listing to Firestore: \(error)")
    }
}
