import Foundation

extension CodingUserInfoKey {
  static let contentIdentifier = CodingUserInfoKey(rawValue: "contentIdentifier")!
}

struct EOEnvelope<Content: Decodable>: Decodable {
  
  let content: Content
  
  private struct CodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int? = nil
    
    init?(stringValue: String) {
      self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
      return nil
    }
  }
  
  init(from decoder: Decoder) throws {
    guard let ci = decoder.userInfo[CodingUserInfoKey.contentIdentifier],
          let contentIdentifier = ci as? String,
          let key = CodingKeys(stringValue: contentIdentifier) else {
            throw EOError.invalidDecoderConfiguration
          }
    let container = try decoder.container(keyedBy: CodingKeys.self)
    content = try container.decode(Content.self, forKey: key)
  }
}
