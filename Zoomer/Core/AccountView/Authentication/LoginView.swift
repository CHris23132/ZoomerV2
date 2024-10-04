import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var nickname: String = ""  // Nickname field for registration
    @Binding var isUserLoggedIn: Bool

    var body: some View {
        VStack {
            Text("Welcome")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 20)

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            if !isUserLoggedIn {
                TextField("Nickname", text: $nickname)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
            }

            Button(action: login) {
                Text("Log In")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()

            Button(action: register) {
                Text("Sign Up")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
            }
        }
        .padding()
    }

    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error during login: \(error.localizedDescription)")
            } else {
                print("User logged in successfully")
                isUserLoggedIn = true
            }
        }
    }

    func register() {
        guard !nickname.isEmpty else {
            print("Nickname is required")
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error during sign-up: \(error.localizedDescription)")
            } else if let user = authResult?.user {
                saveUserDetails(for: user)
                print("User registered successfully")
                isUserLoggedIn = true
            }
        }
    }

    func saveUserDetails(for user: User) {
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).setData([
            "email": user.email ?? "",
            "nickname": nickname
        ]) { error in
            if let error = error {
                print("Error saving user details: \(error.localizedDescription)")
            } else {
                print("User details saved successfully")
            }
        }
    }
}
