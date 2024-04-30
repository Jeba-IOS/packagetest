
import Foundation
import Alamofire

import Foundation
import UIKit
final public class ConnectionHandler : NSObject {
    static let shared = ConnectionHandler()
    private let alamofireManager : Session
    //var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var preference = UserDefaults.standard
    let strDeviceType = "1"
   // let strDeviceToken = Utilities.sharedInstance.getDeviceToken()
  //  var support = UberSupport()
  //  var handler = LocalCacheHandler()
    
    override init() {
        print("Singleton initialized")
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 300 // seconds
        configuration.timeoutIntervalForResource = 500
        alamofireManager = Session.init(configuration: configuration,
                                        serverTrustManager: .none)//Alamofire.SessionManager(configuration: configuration)
    }
    func getRequest(for api : String,
                    APIUrl : String,
                    params : Parameters) -> APIResponseProtocol{
       // if HTTPMethod.get == HTTPMethod.get {
            return self.getRequest(forAPI: APIUrl + api,
                                   params: params,
                                   APIUrl: api)
       // } else {
         //   return self.postRequest(forAPI: APIUrl + api, APIUrl: APIUrl,
           //                         params: params)
        //}
    }
    
    func networkChecker(with StartTime:Date,
                        EndTime: Date,
                        ContentData: Data?) {
        
        let dataInByte = ContentData?.count
        
        if let dataInByte = dataInByte {
            
            // Standard Values
            let standardMinContentSize : Float = 3
            let standardKbps : Float = 2
            
            // Kb Conversion
            let dataInKb : Float = Float(dataInByte / 1000)
            
            // Time Interval Calculation
            let milSec  = EndTime.timeIntervalSince(StartTime)
            let duration = String(format: "%.01f", milSec)
            let dur: Float = Float(duration) ?? 0
            
            // Kbps Calculation
            let Kbps = dataInKb / dur
            
            if dataInKb > standardMinContentSize {
                if Kbps < standardKbps {
                    print("å:::: Low Network Kbps : \(Kbps)")
                  
                } else {
                    print("å:::: Normal NetWork Kbps : \(Kbps)")
                }
            } else {
                print("å:::: Small Content : \(Kbps)")
            }
            
        }
    }
    
    func postRequest(forAPI api: String,APIUrl:String, params: JSON) -> APIResponseProtocol {
        let responseHandler = APIResponseHandler()
        var parameters = params
        let startTime = Date()
//        parameters["token"] = preference.string(forKey: USER_ACCESS_TOKEN)
//        parameters["user_type"] = Global_UserType
//        parameters["device_id"] = strDeviceToken
        parameters["device_type"] = strDeviceType
        alamofireManager.request(api,
                                 method: .post,
                                 parameters: parameters,
                                 encoding: URLEncoding.default,
                                 headers: nil)
            .responseJSON { (response) in
                print("Å api : ",response.request?.url ?? ("\(api)\(parameters)"))
                
                let endTime = Date()
                
                self.networkChecker(with: startTime, EndTime: endTime, ContentData: response.data)
                
                guard response.response?.statusCode != 401 else{//Unauthorized
                    if response.request?.url?.description.contains(APIUrl) ?? false{
                    }
                    return
                }
                
                guard response.response?.statusCode != 503 else { // Web Under Maintenance
                    return
                }
                switch response.result{
                case .success(let value):
                    let json = value as! JSON
                    let error = json.string("error")
                    guard error.isEmpty else{
                        if error == "user_not_found"
                            && response.request?.url?.description.contains(APIUrl) ?? false{
                        }
                        return
                    }
                    if json.isSuccess
                        || !api.contains(APIUrl)
                        || response.response?.statusCode == 200{
                        
                        responseHandler.handleSuccess(value: value,data: response.data ?? Data())
                    }else{
                        responseHandler.handleFailure(value: json.status_message)
                    }
                case .failure(let error):
                    if error._code == 13 {
                        responseHandler.handleFailure(value: "No internet connection.".localizedCapitalized)
                    } else {
                        responseHandler.handleFailure(value: error.localizedDescription)
                    }
                }
            }
        
        
        return responseHandler
    }
   
    func getRequest(forAPI api: String,
                    params: JSON,
                    APIUrl: String
                    ) -> APIResponseProtocol {
        let responseHandler = APIResponseHandler()
        var parameters = params
        let startTime = Date()
//        parameters["token"] = preference.string(forKey: USER_ACCESS_TOKEN)
//        parameters["user_type"] = Global_UserType
//        parameters["device_id"] =  Constants().GETVALUE(keyname: USER_DEVICE_TOKEN) //strDeviceToken
        parameters["device_type"] = strDeviceType
 
        
    
        alamofireManager.request(api,
                                 method: .get,
                                 parameters: parameters,
                                 encoding: URLEncoding.default,
                                 headers: nil)
            .responseJSON { (response) in
                print("Å api : ",response.request?.url ?? ("\(api)\(params)"))
                let endTime = Date()
                
                self.networkChecker(with: startTime, EndTime: endTime, ContentData: response.data)
                
                guard response.response?.statusCode != 503 else { // Web Under Maintenance
                  //  self.webServiceUnderMaintenance()
                  //  Shared.instance.removeLoaderInWindow()
                    return
                }
                
                guard response.response?.statusCode != 401 else{//Unauthorized
                    if response.request?.url?.description.contains(APIUrl) ?? false{
                       // self.doLogoutActions()
                    }
                    return
                }
                switch response.result {
                case .success(let value):
                    let json = value as! JSON
                   
                    let error = json.string("status")
               //     guard error.isEmpty else{
                        if error == "Token is Invalid"
                            && response.request?.url?.description.contains(APIUrl) ?? false{
                           
                        }
                   //     return
                   
                    if json.isSuccess
                        || !api.contains(APIUrl)
                        || response.response?.statusCode == 200 {
                        
                        responseHandler.handleSuccess(value: value,data: response.data ?? Data())
                    }else{
                        responseHandler.handleFailure(value: json.status_message)
                    }
                case .failure(let error):
                    if error._code == 13 {
                        responseHandler.handleFailure(value: "No internet connection.".localizedCapitalized)
                    } else {
                        responseHandler.handleFailure(value: error.localizedDescription)
                    }
                }
            }
        
        
        return responseHandler
    }
   
  

    
    

    
    
    
 
}


//MARK:- response handlers



protocol APIResponseProtocol{
    func responseDecode<T: Decodable>(to modal : T.Type,
                              _ result : @escaping Closure<T>) -> APIResponseProtocol
    func responseJSON(_ result : @escaping Closure<JSON>) -> APIResponseProtocol
    func responseFailure(_ error :@escaping Closure<String>)
}


typealias Closure<T> = (T)->()
typealias JSON = [String: Any]

extension JSONDecoder{
    func decode<T : Decodable>(_ model : T.Type,
                               result : @escaping Closure<T>) ->Closure<Data>{
        return { data in
            do{
                let value = try self.decode(model.self, from: data)
                result(value)
                
            }catch{
                print(error.localizedDescription)
            }
        }
    }
}

class APIResponseHandler : APIResponseProtocol{
  
    init(){
    }
    var jsonSeq : Closure<JSON>?
    var dataSeq : Closure<Data>?
    var errorSeq : Closure<String>?
    
    func responseDecode<T>(to modal: T.Type, _ result: @escaping Closure<T>) -> APIResponseProtocol where T : Decodable {
        
        let decoder = JSONDecoder()
        self.dataSeq =  decoder.decode(modal, result: result)
        return self
    }
    
    func responseJSON(_ result: @escaping Closure<JSON>) -> APIResponseProtocol {
        self.jsonSeq = result
        return self
    }
    func responseFailure(_ error: @escaping Closure<String>) {
        self.errorSeq = error
        
      }
      

    

    func handleSuccess(value : Any,data : Data){
        if let jsonEscaping = self.jsonSeq{
            jsonEscaping(value as! JSON)
        }
        if let dataEscaping = dataSeq{
            dataEscaping(data)
            
        }
    }
    func handleFailure(value : String){
        self.errorSeq?(value)
     }
   
}
extension Dictionary where Dictionary == JSON {
    var status_code : Int{
        return Int(self["status_code"] as? String ?? String()) ?? Int()
    }
    
    var access_token : String {
        return String(self["access_token"] as? String ?? String())
    }
    var video_id : Int {
        return Int(self["video_id"] as? Int ?? Int())
    }
    var isSuccess : Bool{
        return status_code != 0
    }
//    init?(_ data : Data){
//          if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]{
//              self = json
//          }else{
//              return nil
//          }
//      }
    var status_message : String{
        
        let statusMessage = self.string("status_message")
        let successMessage = self.string("success_message")
        return statusMessage.isEmpty ? successMessage : statusMessage
    }

//    var success_message : String{
//        return self["success_message"] as? String ?? String()
//    }
    
    func array<T>(_ key : String) -> [T]{
        return self[key] as? [T] ?? [T]()
    }
    func array(_ key : String) -> [JSON]{
        return self[key] as? [JSON] ?? [JSON]()
    }
    func json(_ key : String) -> JSON{
        return self[key] as? JSON ?? JSON()
    }
     func string(_ key : String)-> String{
     // return self[key] as? String ?? String()
         let value = self[key]
         if let str = value as? String{
            return str
         }else if let int = value as? Int{
            return int.description
         }else if let double = value as? Double{
            return double.description
         }else{
            return String()
         }
     }
    func nsString(_ key: String)-> NSString {
        return self.string(key) as NSString
    }
     func int(_ key : String)-> Int{
         //return self[key] as? Int ?? Int()
         let value = self[key]
         if let str = value as? String{
            return Int(str) ?? Int()
         }else if let int = value as? Int{
            return int
         }else if let double = value as? Double{
            return Int(double)
         }else{
            return Int()
         }
     }
     func double(_ key : String)-> Double{
     //return self[key] as? Double ?? Double()
         let value = self[key]
         if let str = value as? String{
            return Double(str) ?? Double()
         }else if let int = value as? Int{
            return Double(int)
         }else if let double = value as? Double{
            return double
         }else{
            return Double()
         }
     }
    
    func bool(_ key : String) -> Bool{
        let value = self[key]
        if let bool = value as? Bool{
            return bool
        }else if let int = value as? Int{
            return int == 1
        }else if let str = value as? String{
            return ["1","true"].contains(str)
        }else{
            return Bool()
        }
    }
}



