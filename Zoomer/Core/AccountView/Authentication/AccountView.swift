import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct Package: Identifiable {
    var id: String
    var price: Double
    var description: String
    var mediaUrl: String
    var mediaType: String // "image"
}

struct AccountView: View {
    @State private var profileImageUrl: String = ""
    @State private var nickname: String = ""
    @State private var rating: Double = 4.35
    @State private var packages: [Package] = [] // Updated to store user packages
    @State private var reviews: [String] = []
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showAddPackagePopup = false // Control for showing the Add Package Popup
    @State private var useCamera: Bool = false
    @State private var isSubmitting = false // Added to track if an upload is in progress
    @State private var showPaymentSetup = false // Control for showing PaymentSetupView
    @Binding var isUserLoggedIn: Bool

    var body: some View {
        NavigationView {
            VStack {
                // Top Profile Info
                HStack(spacing: 20) {
                    ZStack {
                        if let url = URL(string: profileImageUrl), !profileImageUrl.isEmpty {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else {
                                    ProgressView()
                                }
                            }
                        } else {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 120, height: 120)
                                .overlay(Text("No Image").foregroundColor(.white))
                        }
                        // Edit Button Overlay on Image
                        Button(action: {
                            showImagePicker.toggle()
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .resizable()
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .padding(4)
                        }
                        .sheet(isPresented: $showImagePicker) {
                            ImagePicker(image: $selectedImage, useCamera: $useCamera)
                                .onDisappear {
                                    if let _ = selectedImage {
                                        uploadProfilePicture() // Trigger the upload when a new image is selected
                                    }
                                }
                        }
                    }

                    VStack(alignment: .leading) {
                        Text(nickname)
                            .font(.title)
                            .fontWeight(.bold)

                        HStack {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(rating) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                            }
                        }
                        Text("\(rating, specifier: "%.2f") star rating")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding()

                // User Services / Packages Section
                VStack(alignment: .leading) {
                    HStack {
                        Text("User Services/Packages")
                            .font(.headline)
                        Spacer()
                        // Plus button for adding new service/package
                        Button(action: {
                            showAddPackagePopup = true
                        }) {
                            Image(systemName: "plus.circle")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(packages) { package in
                                VStack {
                                    // Display image based on package media type
                                    if package.mediaType == "image" {
                                        AsyncImage(url: URL(string: package.mediaUrl)) { phase in
                                            if let image = phase.image {
                                                image
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 100, height: 100)
                                                    .cornerRadius(8)
                                            } else {
                                                ProgressView()
                                                    .frame(width: 100, height: 100)
                                            }
                                        }
                                    }

                                    Text("\(package.description)")
                                        .font(.caption)
                                        .frame(width: 100)
                                        .multilineTextAlignment(.center)
                                    Text("$\(String(format: "%.2f", package.price))")
                                        .font(.caption)
                                        .frame(width: 100)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(8)
                            }
                        }
                    }
                }
                .padding(.leading)

                // Connect Payments Button
                Button(action: {
                    showPaymentSetup = true
                }) {
                    Text("Connect Payments")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .sheet(isPresented: $showPaymentSetup) {
                    PaymentSetupView(onDismiss: { showPaymentSetup = false })
                }

                // Reviews Section
                VStack(alignment: .leading) {
                    Text("Reviews")
                        .font(.headline)
                        .padding(.leading)

                    if reviews.isEmpty {
                        Text("No reviews yet.")
                            .padding()
                    } else {
                        List(reviews, id: \.self) { review in
                            HStack {
                                Image("review_placeholder") // Replace with actual review images
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                                Text(review)
                                    .font(.body)
                                    .padding()
                            }
                        }
                    }
                }
                Spacer()
            }
            .onAppear(perform: fetchAccountData)
            .navigationBarTitle("Account")
            .navigationBarItems(trailing: Button("Logout") {
                try? Auth.auth().signOut()
                isUserLoggedIn = false
            })
            // Show the "Add Package" popup modal
            .sheet(isPresented: $showAddPackagePopup) {
                AddPackageView(onDismiss: { showAddPackagePopup = false }) // Modal popup for adding packages
            }
        }
    }

    // Fetch user account data and packages
    private func fetchAccountData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()

        // Fetch user details
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                self.nickname = data["nickname"] as? String ?? "No Name"
                self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
                self.rating = data["rating"] as? Double ?? 4.35
                self.reviews = data["reviews"] as? [String] ?? []
            }
        }

        // Fetch user packages
        db.collection("users").document(userId).collection("packages").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching packages: \(error.localizedDescription)")
                return
            }

            if let documents = snapshot?.documents {
                print("Fetched \(documents.count) packages")
                self.packages = documents.compactMap { document -> Package? in
                    let data = document.data()

                    // Handle both Double and Int for price
                    let price: Double
                    if let doublePrice = data["price"] as? Double {
                        price = doublePrice
                    } else if let intPrice = data["price"] as? Int {
                        price = Double(intPrice) // Convert Int to Double
                    } else {
                        print("Missing or invalid price for document: \(document.documentID)")
                        return nil
                    }

                    guard let description = data["description"] as? String else {
                        print("Missing description for document: \(document.documentID)")
                        return nil
                    }

                    guard let mediaUrl = data["mediaUrl"] as? String else {
                        print("Missing mediaUrl for document: \(document.documentID)")
                        return nil
                    }

                    return Package(id: document.documentID, price: price, description: description, mediaUrl: mediaUrl, mediaType: "image")
                }
            } else {
                print("No packages found")
            }
        }
    }

    // Upload profile picture logic with old image deletion
    private func uploadProfilePicture() {
        guard let image = selectedImage, let userId = Auth.auth().currentUser?.uid else { return }

        isSubmitting = true

        let currentStorageRef = Storage.storage().reference().child("profile_pictures/\(userId).jpg")

        // Step 1: Check if there is an existing profile picture
        if !profileImageUrl.isEmpty {
            let oldImageRef = Storage.storage().reference(forURL: profileImageUrl)
            oldImageRef.delete { error in
                if let error = error {
                    print("Error deleting old profile image: \(error.localizedDescription)")
                } else {
                    print("Old profile image deleted successfully")
                }

                // Step 2: Upload the new image after deleting the old one
                uploadNewProfileImage(to: currentStorageRef)
            }
        } else {
            // No existing image, just upload the new one
            uploadNewProfileImage(to: currentStorageRef)
        }
    }

    private func uploadNewProfileImage(to storageRef: StorageReference) {
        guard let imageData = selectedImage?.jpegData(compressionQuality: 0.75) else {
            print("Failed to convert image to data")
            isSubmitting = false
            return
        }

        // Upload the new image to Firebase Storage
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                isSubmitting = false
                return
            }

            // Get the download URL of the new image
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    isSubmitting = false
                    return
                }

                if let imageUrl = url?.absoluteString {
                    let db = Firestore.firestore()
                    db.collection("users").document(Auth.auth().currentUser!.uid).updateData(["profileImageUrl": imageUrl]) { error in
                        if let error = error {
                            print("Error updating profile image URL: \(error.localizedDescription)")
                        } else {
                            print("Profile image updated successfully")
                            self.profileImageUrl = imageUrl
                        }
                        isSubmitting = false
                    }
                }
            }
        }
    }
}
