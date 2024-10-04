import Foundation
import FirebaseFirestore
import CoreLocation

struct JobListing: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var category: String
    var locationType: String
    var address: String?
    var imageUrl: String?
    var timestamp: Date
    var postedByUserId: String
    var postedByName: String
    var status: String
    var latitude: Double?  // Latitude for location
    var longitude: Double? // Longitude for location
    var rating: Double?  // Optional rating field

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    static let placeholder = JobListing(
        id: nil,
        title: "Placeholder Title",
        description: "Placeholder Description",
        category: "Placeholder Category",
        locationType: "World",
        address: nil,
        imageUrl: nil,
        timestamp: Date(),
        postedByUserId: "PlaceholderUserId",
        postedByName: "Placeholder Name",
        status: "Pending",
        latitude: nil,
        longitude: nil,
        rating: nil // Placeholder rating
    )
}
