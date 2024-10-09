import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import CoreLocation

struct PostJobView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedCategory: String = "Labour Work"
    @State private var address: String = ""
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedImage: UIImage?
    @State private var showImagePicker: Bool = false
    @State private var showLocationPicker: Bool = false
    @State private var isPosting: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var useCamera = false // Set to false for photo library by default
    
    private let categories = ["Labour Work", "Craft Labour", "Tech/IT", "Design", "Photo/Video/Arts"]
    private let geocoder = CLGeocoder()
    
    var body: some View {
        NavigationView {
            ScrollView { // Make the whole view scrollable
                VStack(spacing: 15) {
                    // MARK: - Job Title Input
                    TextField("Job Title", text: $title)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .autocorrectionDisabled(false) // Enable autocorrection
                        .textInputAutocapitalization(.sentences) // Capitalize sentences
                        .padding(.horizontal)

                    // MARK: - Job Description Input
                    TextEditor(text: $description)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .frame(height: 150)
                        .autocorrectionDisabled(false) // Enable autocorrection
                        .textInputAutocapitalization(.sentences) // Capitalize sentences

                    // MARK: - Category Picker
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    // MARK: - Address Input
                    VStack(alignment: .leading) {
                        Text("Address")
                            .font(.headline)
                        TextField("Enter Address", text: $address)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .autocorrectionDisabled(false) // Enable autocorrection
                            .textInputAutocapitalization(.words) // Capitalize words
                    }
                    .padding(.bottom)

                    // MARK: - Location Picker Button
                    Button(action: {
                        showLocationPicker.toggle()
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Set Location on Map")
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                    .sheet(isPresented: $showLocationPicker) {
                        LocationPickerView(selectedAddress: $address, selectedCoordinate: $selectedCoordinate)
                    }

                    // MARK: - Image Picker
                    Button(action: {
                        showImagePicker.toggle()
                    }) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .cornerRadius(8)
                        } else {
                            HStack {
                                Image(systemName: "photo")
                                Text("Add a Photo")
                            }
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                        }
                    }
                    .sheet(isPresented: $showImagePicker) {
                        ImagePicker(image: $selectedImage, useCamera: $useCamera)
                    }

                    // MARK: - Post Job Button
                    Button(action: {
                        postJob()
                    }) {
                        Text("Post Job")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isPosting || title.isEmpty || description.isEmpty || address.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(isPosting || title.isEmpty || description.isEmpty || address.isEmpty)
                    .padding(.top, 20)

                    Spacer()
                }
                .padding()
            }
            .navigationBarTitle("Post a Job", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    // MARK: - Post Job Logic
    private func postJob() {
        guard !title.isEmpty, !description.isEmpty, !address.isEmpty else { return }
        
        isPosting = true
        
        // Geocode the address to get coordinates
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            if let error = error {
                self.alertMessage = "Failed to get location: \(error.localizedDescription)"
                self.showAlert = true
                self.isPosting = false
                return
            }
            
            guard let placemark = placemarks?.first, let location = placemark.location else {
                self.alertMessage = "Invalid location"
                self.showAlert = true
                self.isPosting = false
                return
            }
            
            self.selectedCoordinate = location.coordinate
            
            // Upload to Firestore
            self.saveJobListing()
        }
    }

    private func saveJobListing() {
        guard let user = Auth.auth().currentUser else {
            self.alertMessage = "User not logged in"
            self.showAlert = true
            self.isPosting = false
            return
        }

        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(user.uid)
        
        userDocRef.getDocument { (document, error) in
            if let document = document, document.exists, let data = document.data() {
                let nickname = data["nickname"] as? String ?? "Anonymous"
                
                // Build mutable Job Listing object
                var jobListing = JobListing(
                    id: UUID().uuidString,
                    title: title,
                    description: description,
                    category: selectedCategory,
                    locationType: "Local", // Hardcoded to "Local"
                    address: address,
                    imageUrl: nil, // Will be updated after image upload
                    timestamp: Date(),
                    postedByUserId: user.uid,
                    postedByName: nickname,
                    status: "Open",
                    latitude: selectedCoordinate?.latitude,
                    longitude: selectedCoordinate?.longitude,
                    rating: 0.0 // or another default value if applicable
                )

                // If an image is selected, upload it first
                if let selectedImage = selectedImage {
                    uploadImage(selectedImage) { imageUrl in
                        jobListing.imageUrl = imageUrl // Update the mutable copy
                        self.saveToFirestore(jobListing)
                    }
                } else {
                    self.saveToFirestore(jobListing)
                }
            } else {
                self.alertMessage = "Error fetching user data"
                self.showAlert = true
                self.isPosting = false
            }
        }
    }
    
    // MARK: - Image Upload Logic
    private func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        let storageRef = Storage.storage().reference().child("job_images/\(UUID().uuidString).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.75) else { return }

        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                self.alertMessage = "Error uploading image: \(error.localizedDescription)"
                self.showAlert = true
                completion(nil)
                return
            }
            storageRef.downloadURL { url, error in
                if let error = error {
                    self.alertMessage = "Error getting image URL: \(error.localizedDescription)"
                    self.showAlert = true
                    completion(nil)
                    return
                }
                completion(url?.absoluteString)
            }
        }
    }
    
    // MARK: - Save Job Listing to Firestore
    private func saveToFirestore(_ jobListing: JobListing) {
        let db = Firestore.firestore()
        do {
            _ = try db.collection("job_listings").addDocument(from: jobListing)
            self.alertMessage = "Job posted successfully!"
            self.presentationMode.wrappedValue.dismiss()
        } catch {
            self.alertMessage = "Error saving job listing: \(error.localizedDescription)"
        }
        self.showAlert = true
        self.isPosting = false
    }
}

