//
//  ImgurGalleryDataModel.swift
//  ImgurChallenge
//
//  Created by Matt Bearson on 4/9/19.
//  Copyright © 2019 Matt Bearson. All rights reserved.
//

// To parse the JSON, add this file to your project and do:
//
//   let imgurGalleryDataModel = try? newJSONDecoder().decode(ImgurGalleryDataModel.self, from: jsonData)

import Foundation

struct ImgurGalleryDataModel: Codable {
    let data: [Datum]
}

struct Datum: Codable {
    let id, title: String
    let description: JSONNull?
    let datetime: Int
    let cover: String
    let coverWidth, coverHeight: Int
    let accountURL: String
    let accountID: Int
    let privacy: Privacy
    let layout: Layout
    let views: Int
    let link: String
    let ups, downs, points, score: Int
    let isAlbum: Bool
    let vote: JSONNull?
    let favorite, nsfw: Bool
    let section: Section
    let commentCount, favoriteCount: Int
    let topic: Topic
    let topicID, imagesCount: Int
    let inGallery, isAd: Bool
    let tags: [Tag]
    let adType: Int?
    let adURL: String?
    let inMostViral, includeAlbumAds: Bool?
    let images: [Image]?
    let adConfig: AdConfig?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, datetime, cover
        case coverWidth = "cover_width"
        case coverHeight = "cover_height"
        case accountURL = "account_url"
        case accountID = "account_id"
        case privacy, layout, views, link, ups, downs, points, score
        case isAlbum = "is_album"
        case vote, favorite, nsfw, section
        case commentCount = "comment_count"
        case favoriteCount = "favorite_count"
        case topic
        case topicID = "topic_id"
        case imagesCount = "images_count"
        case inGallery = "in_gallery"
        case isAd = "is_ad"
        case tags
        case adType = "ad_type"
        case adURL = "ad_url"
        case inMostViral = "in_most_viral"
        case includeAlbumAds = "include_album_ads"
        case images
        case adConfig = "ad_config"
    }
}

struct AdConfig: Codable {
    let safeFlags: [SafeFlag]
    let highRiskFlags: [String]
    let unsafeFlags: [UnsafeFlag]
    let showsAds: Bool
}

enum SafeFlag: String, Codable {
    case album = "album"
    case gallery = "gallery"
    case inGallery = "in_gallery"
    case onsfwModSafe = "onsfw_mod_safe"
    case pageLoad = "page_load"
    case share = "share"
    case sixthModSafe = "sixth_mod_safe"
}

enum UnsafeFlag: String, Codable {
    case onsfwModUnsafe = "onsfw_mod_unsafe"
    case sixthUnmod = "sixth_unmod"
    case under10 = "under_10"
}

struct Image: Codable {
    let id: String
    let title: JSONNull?
    let description: String?
    let datetime: Int
    let type: TypeEnum
    let animated: Bool
    let width, height, size, views: Int
    let bandwidth: Int
    let vote: JSONNull?
    let favorite: Bool
    let nsfw, section, accountURL, accountID: JSONNull?
    let isAd, inMostViral, hasSound: Bool
    let tags: [JSONAny]
    let adType: Int
    let adURL, edited: String
    let inGallery: Bool
    let link: String
    let mp4Size: Int?
    let mp4: String?
    let gifv: String?
    let hls: String?
    let processing: Processing?
    let commentCount, favoriteCount, ups, downs: JSONNull?
    let points, score: JSONNull?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, datetime, type, animated, width, height, size, views, bandwidth, vote, favorite, nsfw, section
        case accountURL = "account_url"
        case accountID = "account_id"
        case isAd = "is_ad"
        case inMostViral = "in_most_viral"
        case hasSound = "has_sound"
        case tags
        case adType = "ad_type"
        case adURL = "ad_url"
        case edited
        case inGallery = "in_gallery"
        case link
        case mp4Size = "mp4_size"
        case mp4, gifv, hls, processing
        case commentCount = "comment_count"
        case favoriteCount = "favorite_count"
        case ups, downs, points, score
    }
}

struct Processing: Codable {
    let status: Status
}

enum Status: String, Codable {
    case completed = "completed"
}

enum TypeEnum: String, Codable {
    case imageJPEG = "image/jpeg"
    case imagePNG = "image/png"
    case videoMp4 = "video/mp4"
}

enum Layout: String, Codable {
    case blog = "blog"
}

enum Privacy: String, Codable {
    case hidden = "hidden"
    case privacyPublic = "public"
}

enum Section: String, Codable {
    case empty = ""
    case supermodelCats = "SupermodelCats"
}

struct Tag: Codable {
    let name, displayName: String
    let followers, totalItems: Int
    let following: Bool
    let backgroundHash: String
    let thumbnailHash: JSONNull?
    let accent: String?
    let backgroundIsAnimated, thumbnailIsAnimated, isPromoted: Bool
    let description: Description
    let logoHash, logoDestinationURL: JSONNull?
    let descriptionAnnotations: DescriptionAnnotations
    
    enum CodingKeys: String, CodingKey {
        case name
        case displayName = "display_name"
        case followers
        case totalItems = "total_items"
        case following
        case backgroundHash = "background_hash"
        case thumbnailHash = "thumbnail_hash"
        case accent
        case backgroundIsAnimated = "background_is_animated"
        case thumbnailIsAnimated = "thumbnail_is_animated"
        case isPromoted = "is_promoted"
        case description
        case logoHash = "logo_hash"
        case logoDestinationURL = "logo_destination_url"
        case descriptionAnnotations = "description_annotations"
    }
}

enum Description: String, Codable {
    case allThingsAnimal = "all things animal"
    case cuteAndAdorable = "cute and adorable"
    case empty = ""
    case felineFriends = "feline friends"
    case goOutside = "go outside"
    case heartsAflutter = "hearts aflutter"
    case heroesOnPaper = "Heroes on paper"
    case japaneseAnimation = "japanese animation"
    case loLsROFLsLMAOS = "LOLs, ROFLs, LMAOs"
    case ourFelineFriends = "Our feline friends"
    case powBAMZap = "POW! BAM! ZAP!"
}

struct DescriptionAnnotations: Codable {
}

enum Topic: String, Codable {
    case noTopic = "No Topic"
}

// MARK: Encode/decode helpers

class JSONNull: Codable, Hashable {
    
    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }
    
    public var hashValue: Int {
        return 0
    }
    
    public init() {}
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

class JSONCodingKey: CodingKey {
    let key: String
    
    required init?(intValue: Int) {
        return nil
    }
    
    required init?(stringValue: String) {
        key = stringValue
    }
    
    var intValue: Int? {
        return nil
    }
    
    var stringValue: String {
        return key
    }
}

class JSONAny: Codable {
    let value: Any
    
    static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode JSONAny")
        return DecodingError.typeMismatch(JSONAny.self, context)
    }
    
    static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
        let context = EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode JSONAny")
        return EncodingError.invalidValue(value, context)
    }
    
    static func decode(from container: SingleValueDecodingContainer) throws -> Any {
        if let value = try? container.decode(Bool.self) {
            return value
        }
        if let value = try? container.decode(Int64.self) {
            return value
        }
        if let value = try? container.decode(Double.self) {
            return value
        }
        if let value = try? container.decode(String.self) {
            return value
        }
        if container.decodeNil() {
            return JSONNull()
        }
        throw decodingError(forCodingPath: container.codingPath)
    }
    
    static func decode(from container: inout UnkeyedDecodingContainer) throws -> Any {
        if let value = try? container.decode(Bool.self) {
            return value
        }
        if let value = try? container.decode(Int64.self) {
            return value
        }
        if let value = try? container.decode(Double.self) {
            return value
        }
        if let value = try? container.decode(String.self) {
            return value
        }
        if let value = try? container.decodeNil() {
            if value {
                return JSONNull()
            }
        }
        if var container = try? container.nestedUnkeyedContainer() {
            return try decodeArray(from: &container)
        }
        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self) {
            return try decodeDictionary(from: &container)
        }
        throw decodingError(forCodingPath: container.codingPath)
    }
    
    static func decode(from container: inout KeyedDecodingContainer<JSONCodingKey>, forKey key: JSONCodingKey) throws -> Any {
        if let value = try? container.decode(Bool.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Int64.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Double.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(String.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeNil(forKey: key) {
            if value {
                return JSONNull()
            }
        }
        if var container = try? container.nestedUnkeyedContainer(forKey: key) {
            return try decodeArray(from: &container)
        }
        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key) {
            return try decodeDictionary(from: &container)
        }
        throw decodingError(forCodingPath: container.codingPath)
    }
    
    static func decodeArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
        var arr: [Any] = []
        while !container.isAtEnd {
            let value = try decode(from: &container)
            arr.append(value)
        }
        return arr
    }
    
    static func decodeDictionary(from container: inout KeyedDecodingContainer<JSONCodingKey>) throws -> [String: Any] {
        var dict = [String: Any]()
        for key in container.allKeys {
            let value = try decode(from: &container, forKey: key)
            dict[key.stringValue] = value
        }
        return dict
    }
    
    static func encode(to container: inout UnkeyedEncodingContainer, array: [Any]) throws {
        for value in array {
            if let value = value as? Bool {
                try container.encode(value)
            } else if let value = value as? Int64 {
                try container.encode(value)
            } else if let value = value as? Double {
                try container.encode(value)
            } else if let value = value as? String {
                try container.encode(value)
            } else if value is JSONNull {
                try container.encodeNil()
            } else if let value = value as? [Any] {
                var container = container.nestedUnkeyedContainer()
                try encode(to: &container, array: value)
            } else if let value = value as? [String: Any] {
                var container = container.nestedContainer(keyedBy: JSONCodingKey.self)
                try encode(to: &container, dictionary: value)
            } else {
                throw encodingError(forValue: value, codingPath: container.codingPath)
            }
        }
    }
    
    static func encode(to container: inout KeyedEncodingContainer<JSONCodingKey>, dictionary: [String: Any]) throws {
        for (key, value) in dictionary {
            let key = JSONCodingKey(stringValue: key)!
            if let value = value as? Bool {
                try container.encode(value, forKey: key)
            } else if let value = value as? Int64 {
                try container.encode(value, forKey: key)
            } else if let value = value as? Double {
                try container.encode(value, forKey: key)
            } else if let value = value as? String {
                try container.encode(value, forKey: key)
            } else if value is JSONNull {
                try container.encodeNil(forKey: key)
            } else if let value = value as? [Any] {
                var container = container.nestedUnkeyedContainer(forKey: key)
                try encode(to: &container, array: value)
            } else if let value = value as? [String: Any] {
                var container = container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
                try encode(to: &container, dictionary: value)
            } else {
                throw encodingError(forValue: value, codingPath: container.codingPath)
            }
        }
    }
    
    static func encode(to container: inout SingleValueEncodingContainer, value: Any) throws {
        if let value = value as? Bool {
            try container.encode(value)
        } else if let value = value as? Int64 {
            try container.encode(value)
        } else if let value = value as? Double {
            try container.encode(value)
        } else if let value = value as? String {
            try container.encode(value)
        } else if value is JSONNull {
            try container.encodeNil()
        } else {
            throw encodingError(forValue: value, codingPath: container.codingPath)
        }
    }
    
    public required init(from decoder: Decoder) throws {
        if var arrayContainer = try? decoder.unkeyedContainer() {
            self.value = try JSONAny.decodeArray(from: &arrayContainer)
        } else if var container = try? decoder.container(keyedBy: JSONCodingKey.self) {
            self.value = try JSONAny.decodeDictionary(from: &container)
        } else {
            let container = try decoder.singleValueContainer()
            self.value = try JSONAny.decode(from: container)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        if let arr = self.value as? [Any] {
            var container = encoder.unkeyedContainer()
            try JSONAny.encode(to: &container, array: arr)
        } else if let dict = self.value as? [String: Any] {
            var container = encoder.container(keyedBy: JSONCodingKey.self)
            try JSONAny.encode(to: &container, dictionary: dict)
        } else {
            var container = encoder.singleValueContainer()
            try JSONAny.encode(to: &container, value: self.value)
        }
    }
}
