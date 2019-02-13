//
//  ViewController.swift
//  DBServiceManager
//
//  Created by digitalbrain@hotmail.it on 02/11/2019.
//  Copyright (c) 2019 digitalbrain@hotmail.it. All rights reserved.
//

import UIKit
import DBServiceManager

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        ServiceManager.shared.loggerEnabled = true
        
        ServiceManager.shared.apiRequest(api: .users, parameters: ["page":1], responseClass: ExampleResponse.self) { (response, error) in
            if let response = response {
                for resp in response.data {
                    print("\(resp.last_name) -> \(resp.first_name) : \(resp.avatar!)")
                }
            }
            
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

struct GenericResponse: Codable {
    
}

struct ExampleResponse: Codable {
    let page: Int
    let per_page: Int
    let total: Int
    let total_pages: Int
    var data: [DataItem] = []
    
}

struct DataItem: Codable {
    let id: Int
    let first_name: String
    let last_name: String
    let avatar: URL?
}

struct Constants {
    static let baseURL: String = "https://reqres.in/api/"
}
enum ApiMethods: String {

    
   case users = "users/"

    func api(method: HttpMethod = .get) -> API {
        return API(url: Constants.baseURL + self.rawValue, method: method)!
    }
}
extension ServiceManager {
    
    @discardableResult  func apiRequest<T:Codable>(api: ApiMethods, parameters:[String: Any]? = nil, responseClass: T.Type , completion:((_ responseObject: T?,_ error: ServiceError?)->())? ) -> URLSessionTask?  {
        return self.apiRequest(api: api.api(), headerParams: nil, parameters: parameters, responseClass: responseClass, completion: completion)
    }

}
