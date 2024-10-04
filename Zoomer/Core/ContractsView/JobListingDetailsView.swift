//
//  JobListingDetailsView.swift
//  Zoomer
//
//  Created by Christopher Walsh on 2024-08-18.
//

import SwiftUI

struct JobListingDetailsView: View {
    var jobListing: JobListing
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text(jobListing.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(jobListing.description)
                    .font(.body)
                    .padding(.bottom, 10)
                
                Text("Category: \(jobListing.category)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if let address = jobListing.address {
                    Text("Location: \(address)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 5)
            
            Spacer()
            
            NavigationLink(destination: ProposalView(jobListing: jobListing)) {
                Text("View Proposals")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .padding()
        .background(Color(.systemGray6).ignoresSafeArea())
        .navigationBarTitle("Job Details", displayMode: .inline)
    }
}
