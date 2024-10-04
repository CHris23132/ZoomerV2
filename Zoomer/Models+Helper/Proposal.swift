import Foundation

// Ensure that Proposal conforms to Codable (which includes Decodable)
struct Proposal: Identifiable, Codable {
    var id: String?
    var jobId: String
    var price: Double
    var proposalMessage: String
    var completionDate: Date
    var workerId: String  // sellerId
    var workerName: String
    var buyerId: String  // buyerId
}
