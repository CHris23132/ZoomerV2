import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

struct EditAccountView: View {
    @State private var username: String = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isSubmitting = false
    @State private var useCamera = false // Control ImagePicker
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // MARK: - Profile Image Upload Section
                Button(action: {
                    showImagePicker.toggle()
                }) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                            .shadow(radius: 5)
                            .padding(.top)
                    } else {
                        VStack {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.gray)
                                .padding(.top)
                            Text("Upload Profile Picture")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        .padding()
                    }
                }
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(image: $selectedImage, useCamera: $useCamera)
                }

                // MARK: - Username Input Field
                VStack(alignment: .leading) {
                    Text("Username")
                        .font(.headline)
                        .padding(.leading)
                    TextField("Enter your username", text: $username)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }

                // MARK: - Save Changes Button
                Button(action: saveAccountChanges) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text("Save Changes")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isSubmitting || username.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .shadow(radius: isSubmitting ? 0 : 5)
                }
                .disabled(isSubmitting || username.isEmpty)
                
                Spacer()
            }
            .padding(.top)
            .background(Color(.systemGray6).edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Edit Account", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                onDismiss()
            })
        }
    }

    // MARK: - Save Account Changes
    private func saveAccountChanges() {
        guard !username.isEmpty || selectedImage != nil else {
            print("No changes to save.")
            return
        }

        isSubmitting = true

        updateUserProfile(username: username.isEmpty ? nil : username, profileImage: selectedImage) { error in
            if let error = error {
                print("Error updating account: \(error.localizedDescription)")
            } else {
                print("Account updated successfully.")
            }
            isSubmitting = false
            onDismiss()
        }
    }
}

// MARK: - Helper Functions for User Profile Update

// Function to update user profile
func updateUserProfile(username: String?, profileImage: UIImage?, completion: @escaping (Error?) -> Void) {
    guard let userId = Auth.auth().currentUser?.uid else {
        print("Error: User is not logged in.")
        return
    }

    let db = Firestore.firestore()
    let userRef = db.collection("users").document(userId)

    if let profileImage = profileImage {
        uploadProfileImage(image: profileImage) { result in
            switch result {
            case .success(let imageUrl):
                var data: [String: Any] = [:]
                if let username = username {
                    data["username"] = username
                }
                data["profileImageUrl"] = imageUrl

                userRef.setData(data, merge: true) { error in
                    completion(error)
                }
            case .failure(let error):
                completion(error)
            }
        }
    } else {
        var data: [String: Any] = [:]
        if let username = username {
            data["username"] = username
        }

        userRef.setData(data, merge: true) { error in
            completion(error)
        }
    }
}

// Function to upload profile image
func uploadProfileImage(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
    guard let userId = Auth.auth().currentUser?.uid else {
        print("Error: User is not logged in.")
        return
    }

    let storageRef = Storage.storage().reference().child("profile_pictures/\(userId).jpg")
    guard let imageData = image.jpegData(compressionQuality: 0.75) else {
        print("Error: Could not compress image.")
        return
    }

    let imageSizeMB = Double(imageData.count) / (1024 * 1024)
    if imageSizeMB > 2.5 {
        print("Error: Image size exceeds 2.5 MB.")
        return
    }

    storageRef.putData(imageData, metadata: nil) { metadata, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        storageRef.downloadURL { url, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let imageUrl = url?.absoluteString else {
                print("Error: Image URL is nil.")
                return
            }

            completion(.success(imageUrl))
        }
    }
}
