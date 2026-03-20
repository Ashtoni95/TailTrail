//
//  DogBreed.swift
//  TailTrail
//
//

// Models/DogBreed.swift
import Foundation

enum DogBreed: String, CaseIterable {
    case unknown = "Don't Know"
    case labrador = "Labrador"
    case goldenRetriever = "Golden Retriever"
    case germanShepherd = "German Shepherd"
    case bulldog = "Bulldog"
    case poodle = "Poodle"
    case beagle = "Beagle"
    case rottweiler = "Rottweiler"
    case yorkshireTerrier = "Yorkshire Terrier"
    case boxer = "Boxer"
    case dachshund = "Dachshund"
    case husky = "Husky"
    case greatDane = "Great Dane"
    case doberman = "Doberman"
    case shihTzu = "Shih Tzu"
    case maltese = "Maltese"
    case bostonTerrier = "Boston Terrier"
    case cavalierKingCharles = "Cavalier King Charles"
    case shetlandSheepdog = "Shetland Sheepdog"
    case belgianMalinois = "Belgian Malinois"
    
    static var allCases: [DogBreed] {
        return [.unknown] + [
            .labrador, .goldenRetriever, .germanShepherd, .bulldog, .poodle,
            .beagle, .rottweiler, .yorkshireTerrier, .boxer, .dachshund,
            .husky, .greatDane, .doberman, .shihTzu, .maltese,
            .bostonTerrier, .cavalierKingCharles, .shetlandSheepdog, .belgianMalinois
        ]
    }
}
