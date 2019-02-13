//
//  Utils.swift
//  DBServiceManager
//
//  Created by Massimiliano on 13/02/2019.
//

extension Encodable {
    public func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
    
    public var dictionary: [String: Any] {
        get {
            if let dict = try? self.asDictionary() {
                return dict
            } else {
                return [:]
            }
        }
    }
}
