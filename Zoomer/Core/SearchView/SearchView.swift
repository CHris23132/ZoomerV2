import SwiftUI
import FirebaseFirestore
import MapKit

struct SearchView: View {
    @State private var selectedCategory: String = "All"
    @State private var jobListings: [JobListing] = []
    @StateObject private var locationManager = LocationManager()
    @State private var searchRadius: Double = 50.0
    @State private var showLocationPicker: Bool = false
    @State private var selectedAddress: String = ""
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedJobListing: JobListing?
    @State private var showJobSubmitView: Bool = false
    
    // Define colors for consistent styling
    private let primaryColor = Color.blue
    private let secondaryColor = Color.white
    private let accentColor = Color.green
    private let backgroundColor = Color(.systemGray6)
    
    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Header
            HStack {
                Button(action: {
                    // Action for post button
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(primaryColor)
                        .padding()
                }
                Spacer()
                Text("Zoomer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(primaryColor)
                Spacer()
                Button(action: {
                    // Action for settings button
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title)
                        .foregroundColor(primaryColor)
                        .padding()
                }
            }
            .padding()
            .background(secondaryColor.shadow(radius: 3))
            
            // MARK: - Location and Radius Filter
            if locationManager.locationPermissionGranted, let userLocation = locationManager.userLocation {
                VStack(spacing: 15) {
                    HStack {
                        Text("Radius: \(Int(searchRadius)) km")
                            .font(.headline)
                            .foregroundColor(primaryColor)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    Slider(value: $searchRadius, in: 1...100, step: 1)
                        .accentColor(primaryColor)
                        .padding(.horizontal)
                        .frame(height: 10)
                }
                .padding()
                .background(secondaryColor)
                .cornerRadius(12)
                .shadow(radius: 3)
            } else {
                // Prompt user to set location
                Button("Set Location") {
                    locationManager.requestLocationPermission()
                    locationManager.startUpdatingLocation()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(primaryColor)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .shadow(radius: 3)
            }
            
            // MARK: - Category Filter
            HStack {
                Text("Categories:")
                    .font(.headline)
                    .foregroundColor(primaryColor)
                Spacer()
                Picker("Categories", selection: $selectedCategory) {
                    Text("All").tag("All")
                    Text("Labour Work").tag("Labour Work")
                    Text("Craft Labour").tag("Craft Labour")
                    Text("Tech/IT").tag("Tech/IT")
                    Text("Design").tag("Design")
                    Text("Photo/Video/Arts").tag("Photo/Video/Arts")
                }
                .pickerStyle(MenuPickerStyle())
                .background(secondaryColor)
                .cornerRadius(8)
            }
            .padding()
            .background(secondaryColor)
            .cornerRadius(12)
            .shadow(radius: 3)
            
            // MARK: - Job Listings List
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(jobListings) { job in
                        JobListingRow(jobListing: job, secondaryColor: secondaryColor, accentColor: accentColor) {
                            self.selectedJobListing = job
                            self.showJobSubmitView.toggle()
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .onAppear {
                // Fetch listings when view appears
                if locationManager.locationPermissionGranted {
                    fetchJobListings()
                }
            }
        }
        .padding()
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showJobSubmitView) {
            if let job = selectedJobListing {
                JobSubmitView(jobListing: job)
            }
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(selectedAddress: $selectedAddress, selectedCoordinate: $selectedCoordinate)
        }
    }
    
    // MARK: - Fetch Job Listings
    private func fetchJobListings() {
        guard let userLocation = locationManager.userLocation else { return }

        let db = Firestore.firestore()
        var query: Query = db.collection("job_listings")
        
        // Apply category filter
        if selectedCategory != "All" {
            query = query.whereField("category", isEqualTo: selectedCategory)
        }
        
        // Only show open jobs
        query = query.whereField("status", isEqualTo: "Open")
        
        query.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching job listings: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No documents found")
                return
            }
            
            // Filter based on distance
            self.jobListings = documents.compactMap { doc -> JobListing? in
                if let job = try? doc.data(as: JobListing.self),
                   let latitude = doc["latitude"] as? Double,
                   let longitude = doc["longitude"] as? Double {
                    let jobCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    let jobLocation = CLLocation(latitude: jobCoordinate.latitude, longitude: jobCoordinate.longitude)
                    let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                    let distance = jobLocation.distance(from: userCLLocation) / 1000.0 // Convert to kilometers
                    
                    // Check if within the specified radius
                    if distance <= self.searchRadius {
                        return job
                    }
                }
                return nil
            }
        }
    }
    
    // MARK: - Job Listing Row View
    struct JobListingRow: View {
        var jobListing: JobListing
        var secondaryColor: Color
        var accentColor: Color
        var onSubmit: () -> Void
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Title and Description
                Text(jobListing.title)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(jobListing.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Image Preview with phase handling
                if let imageUrl = jobListing.imageUrl, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 150)
                        case .success(let image):
                            image
                                .resizable() // Make image resizable
                                .scaledToFit() // Fit the image in the frame
                                .frame(maxHeight: 150)
                                .cornerRadius(8)
                                .shadow(radius: 2)
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                HStack {
                    Text("Posted by: \(jobListing.postedByName)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Spacer()
                    Button("Details", action: onSubmit)
                        .font(.footnote)
                        .padding(8)
                        .background(accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                }
            }
            .padding()
            .background(secondaryColor)
            .cornerRadius(12)
            .shadow(radius: 4)
        }
    }
}
