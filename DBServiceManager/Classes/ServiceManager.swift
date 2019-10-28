//
//  ServiceManager.swift
//  MxmSDK
//
//  Created by Massimiliano on 15/02/17.
//  Copyright © 2017 01TRIBE. All rights reserved.
//

import UIKit

public enum HttpMethod : String, RawRepresentable {
    case post = "POST"
    case get = "GET"
}

public typealias ServiceCompletionHandler = ((_ result: Data?, _ response: URLResponse? , _ error: Error?) -> ())

open class ServiceManager: NSObject, URLSessionDelegate {

    public static let shared = ServiceManager()

    public var sessionConfiguration = URLSessionConfiguration.default
    
    public var loggerEnabled: Bool = false
    
    /**
     Costruisce la URL request
     - parameter endPoint : l'url
     - parameter parameters : Dizionario con chiave e valore dei parametri da inviare nella richiesta
     - parameter headers : Dizionario chiave valore dei campi da inviare come Http header
     - parameter httpMethod: Get/Post
     */
    func request(withUrl endPoint:String, parameters: [String : Any], headers: [String : String], httpMethod: HttpMethod) -> URLRequest {
        var endPoint = endPoint
        if httpMethod == .get {
            var queryString: String {
                 var output: String = ""
                 for (key,value) in parameters {
                     output +=  "\(key)=\(value)&"
                 }
                 output = String(output.dropLast())
                 return output
              }
            endPoint = "\(endPoint)?\(queryString)"
        }
        var request: URLRequest = URLRequest(url: URL(string: endPoint)!)
        request.httpMethod = httpMethod.rawValue
        if httpMethod == .post {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
                request.httpBody = jsonData
                
            } catch {
                
            }
        }
        for aKey in headers.keys {
            request.setValue(headers[aKey], forHTTPHeaderField: aKey)
        }

        return request
    }
    
   
    @discardableResult  func callEndpoint(withUrl endPoint:String, parameters: [String : Any], headers: [String : String], httpMethod: HttpMethod, completion: ServiceCompletionHandler?) -> URLSessionTask {
        let request = self.request(withUrl: endPoint, parameters: parameters, headers: headers, httpMethod: httpMethod)
        return self.callEndpoint(withRequest: request, completion: completion)
    }
    
    
    @discardableResult func callEndpoint(withRequest request: URLRequest, completion: ServiceCompletionHandler?) -> URLSessionTask {
        service_print("______________________________________________________________")
        let request_id = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        service_print("[\(request_id)] Request URL: \(request.url?.absoluteString ?? "")")
        
        if let bodyData = request.httpBody {
            service_print("[\(request_id)] Request data:\n\(NSString(data:bodyData, encoding:1) ?? "")")
        }
        
        var urlSession: URLSession? = URLSession(configuration: self.sessionConfiguration, delegate: self, delegateQueue: nil)
        
        let sessionTask = urlSession?.dataTask(with: request) { (data, response, error) in
        
            if let data = data, self.loggerEnabled {
                if let data = try? JSONSerialization.data(withJSONObject: JSONSerialization.jsonObject(with: data, options: .mutableContainers), options: .prettyPrinted) {
                    service_print("[\(request_id)] Response data:\n\( String(data: data, encoding: .utf8) ?? "nil")")
                } else {
                    service_print("[\(request_id)] Response data:\n\( String(data: data, encoding: .utf8) ?? "nil")")
                }
            }
            
            if let error = error {
                service_print("[\(request_id)] Error: \n \(error.localizedDescription) \n\(error)")
            }
            
            if let response  = response {
                if self.validate(httpResponse: response,request: request, completion: completion) == false {
                    return
                }
            }
            service_print("***********************************************************************")
            completion?(data,response,error)
            
        }
        sessionTask?.resume()
        urlSession?.finishTasksAndInvalidate()
        urlSession = nil
        return sessionTask!
    }

    /**
     Validazione della response (il metodo deve essere implementato nella sottoclasse)
     - parameter aResponse : URLResponse ricevuta
     - parameter completion : Completion da chiamare in caso la validazione non vada a buon fine
     - returns: ritorna true se la response è ritenuta valida, altrimenti è necessario chiamare il completion
     */
 
    open func validate(httpResponse aResponse: URLResponse, request: URLRequest, completion: ServiceCompletionHandler?) -> Bool {
        return true
    }

    //MARK: URLSessionDelegate
    #if IGNORE_SSL
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        
            completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
            
       
        return
    }
    #endif
    

}

public extension ServiceManager {
    
    @discardableResult func apiRequest<T:Codable>(api: API?, headerParams: [String: String]? = nil, parameters:[String: Any]? = nil, responseClass: T.Type , completion:((_ responseObject: T?, _ response: URLResponse? , _ error: ServiceError?)->())? ) -> URLSessionTask?  {
       
        guard let api = api else { completion?(nil,nil,ServiceError(error: DBError.invalidURL, errorCode: -2, errorMessage: "URL is invalid")); return nil }
        let request = self.request(withUrl:api.url.absoluteString, parameters: parameters ?? [:], headers: headerParams ?? [:], httpMethod: api.method)
        
        return self.callEndpoint(withRequest: request) { (data, response, error) in
            if let data = data {
                
                if let responseObject = try? JSONDecoder().decode(T.self, from: data) {
                    completion?(responseObject,response,nil)
                } else {
                    completion?(nil,response ,ServiceError(error: error ?? DBError.jsonEncodeError, errorCode: -1, errorMessage: nil))
                }
                
            } else {
                completion?(nil,response, ServiceError(error: error ?? DBError.emptyData, errorCode: 0, errorMessage: nil))
            }
        }
        
    }
}

public struct ServiceError {
    var error: Error?
    var errorCode: Int?
    var errorMessage: String?
}

public enum DBError: Error {
    case emptyData
    case jsonEncodeError
    case serviceError
    case invalidURL
}


open class API {

    let url: URL
    let method: HttpMethod
    public init?(url: String, method: HttpMethod = .get) {
        if let url = URL(string: url) {
            self.url = url
            self.method = method
        } else {
            return nil
        }
    }
    
}



