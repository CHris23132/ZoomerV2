import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

// MARK: - AccountView
struct AccountView: View {
    @State private var profileImageUrl: String = ""
    @State private var nickname: String = ""
    @State private var rating: Double = 4.35
    @State private var packages: [Package] = [] // Package struct is used from the separate file
    @State private var reviews: [String] = []
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showAddPackagePopup = false
    @State private var useCamera: Bool = false
    @State private var isSubmitting = false
    @State private var showPaymentSetup = false
    @State private var showBankingView = false // Navigation to BankingView
    @Binding var isUserLoggedIn: Bool

    var body: some View {
        NavigationView {
            VStack {
                // MARK: - Profile Info Section
                HStack(spacing: 20) {
                    ZStack {
                        if let url = URL(string: profileImageUrl), !profileImageUrl.isEmpty {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .shadow(radius: 5)
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 120, height: 120)
                                        .overlay(ProgressView())
                                }
                            }
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .overlay(Text("No Image").foregroundColor(.gray))
                        }
                        // Edit Button Overlay
                        Button(action: {
                            showImagePicker.toggle()
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .resizable()
                                .foregroundColor(.blue)
                                .frame(width: 32, height: 32)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 3)
                                .padding(4)
                        }
                        .sheet(isPresented: $showImagePicker) {
                            ImagePicker(image: $selectedImage, useCamera: $useCamera)
                                .onDisappear {
                                    if selectedImage != nil {
                                        uploadProfilePicture()
                                    }
                                }
                        }
                    }
                    .padding(.leading)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(nickname)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        // Star Rating Display
                        HStack {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(rating) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                            }
                        }
                        Text("\(rating, specifier: "%.2f") ★ rating")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.top)

                // MARK: - Services / Packages Section
                VStack(alignment: .leading) {
                    HStack {
                        Text("Services / Packages")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: {
                            showAddPackagePopup = true
                        }) {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .padding(8)
                                .background(Circle().fill(Color.gray.opacity(0.1)))
                        }
                    }
                    .padding([.leading, .trailing, .top])

                    // Horizontal Scroll View for Packages
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(packages) { package in
                                VStack(alignment: .center, spacing: 8) {
                                    if package.mediaType == "image" {
                                        AsyncImage(url: URL(string: package.mediaUrl)) { phase in
                                            if let image = phase.image {
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 120, height: 120)
                                                    .cornerRadius(10)
                                            } else {
                                                Color.gray.opacity(0.2)
                                                    .frame(width: 120, height: 120)
                                                    .cornerRadius(10)
                                            }
                                        }
                                    }
                                    Text(package.description)
                                        .font(.caption)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 120)
                                    Text("$\(String(format: "%.2f", package.price))")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(radius: 3)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // MARK: - Bank Details Button
                NavigationLink(destination: BankingView(), isActive: $showBankingView) {
                    Button(action: {
                        showBankingView = true
                    }) {
                        Text("Bank Details")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding([.leading, .trailing])
                            .shadow(radius: 3)
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
            .sheet(isPresented: $showAddPackagePopup) {
                AddPackageView(onDismiss: { showAddPackagePopup = false })
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Fetch Account Data
    private func fetchAccountData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        // Fetch User Details
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                self.nickname = data["nickname"] as? String ?? "No Name"
                self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
                self.rating = data["rating"] as? Double ?? 4.35
                self.reviews = data["reviews"] as? [String] ?? []
            }
        }

        // Fetch User Packages
        db.collection("users").document(userId).collection("packages").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching packages: \(error.localizedDescription)")
                return
            }

            if let documents = snapshot?.documents {
                self.packages = documents.compactMap { document -> Package? in
                    let data = document.data()

                    let price: Double
                    if let doublePrice = data["price"] as? Double {
                        price = doublePrice
                    } else if let intPrice = data["price"] as? Int {
                        price = Double(intPrice)
                    } else {
                        return nil
                    }

                    guard let description = data["description"] as? String,
                          let mediaUrl = data["mediaUrl"] as? String else {
                        return nil
                    }

                    return Package(id: document.documentID, price: price, description: description, mediaUrl: mediaUrl, mediaType: "image")
                }
            }
        }
    }

    // MARK: - Upload Profile Picture
    private func uploadProfilePicture() {
        guard let image = selectedImage, let userId = Auth.auth().currentUser?.uid else { return }

        isSubmitting = true
        let storageRef = Storage.storage().reference().child("profile_pictures/\(userId).jpg")

        if !profileImageUrl.isEmpty {
            let oldImageRef = Storage.storage().reference(forURL: profileImageUrl)
            oldImageRef.delete { _ in
                uploadNewProfileImage(to: storageRef)
            }
        } else {
            uploadNewProfileImage(to: storageRef)
        }
    }

    private func uploadNewProfileImage(to storageRef: StorageReference) {
        guard let imageData = selectedImage?.jpegData(compressionQuality: 0.75) else {
            isSubmitting = false
            return
        }

        storageRef.putData(imageData, metadata: nil) { _, error in
            if error != nil {
                isSubmitting = false
                return
            }

            storageRef.downloadURL { url, _ in
                if let imageUrl = url?.absoluteString {
                    let db = Firestore.firestore()
                    db.collection("users").document(Auth.auth().currentUser!.uid).updateData(["profileImageUrl": imageUrl]) { _ in
                        self.profileImageUrl = imageUrl
                        isSubmitting = false
                    }
                }
            }
        }
    }
}
