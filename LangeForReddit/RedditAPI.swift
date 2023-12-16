import Foundation
import KeychainAccess

struct ModQueueResponse:  Codable {
    struct Data: Codable {
        struct Children: Codable {
            struct Data: Codable, Hashable {
                let id: String
                let title: String?
            }
            let data: Data
        }
        let children: [Children]
    }
    let data: Data
}


class RedditAPI {
    

    static let shared = RedditAPI()
    
    var accessToken: String?

    // Updated initializer
    private init() {
        let keychain = Keychain(service: "com.Stevereitz.LangeForReddit")
        self.accessToken = keychain["accessToken"]
        print("Token retrieved from Keychain: \(String(describing: self.accessToken))")
    }

    // Method to set the access token
    func setAccessToken(_ newToken: String) {

        print("Token in method is \(newToken)")
        self.accessToken = newToken
        let keychain = Keychain(service: "com.Stevereitz.LangeForReddit")
        do {
            try keychain.set(newToken, key: "accessToken")
            print("Token stored in Keychain: \(newToken)")
        } catch let error {
            print("Error storing token in Keychain: \(error)")
        }
//        keychain["accessToken"] = newToken
        print("Token stored in Keychain")
    }

    func getModQueue(subreddit: String,  completion: @escaping ([ModQueueResponse.Data.Children.Data]) -> ()) {
        print("Access Token: \(String(describing: self.accessToken))")
        let urlString = "https://oauth.reddit.com/r/\(subreddit)/about/modqueue"
        print("URL String: \(urlString)")

        guard let accessToken = self.accessToken, let url = URL(string: urlString) else {
            print("Invalid URL or Access Token")
            return
        }
        
//        guard let accessToken = self.accessToken, let url = URL(string: "https://oauth.reddit.com/r/\(subreddit)/about/modqueue") else {
//            print("Invalid URL or Access Token")
//            return
//        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("Lange/0.1 by ssk42", forHTTPHeaderField: "User-Agent")
        request.httpMethod = "GET"
        print("STR: Sending request to \(url)")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("STR: Error fetching data: \(error)")
                completion([])
                return
            }

            guard let data = data else {
                print("STR: No data returned")
                completion([])
                return
            }

            do {
                print("STR: Received data: \(String(data: data, encoding: .utf8) ?? "")")
                let decodedData = try JSONDecoder().decode(ModQueueResponse.self, from: data)
                let modItems = decodedData.data.children.map { $0.data }
                print("STR: Decoded IDs: \(modItems)")
                DispatchQueue.main.async {
                    completion(modItems)
                }

            } catch let decodingError {
                print("STR: Decoding error: \(decodingError)")
                completion([])
            }
        }
        task.resume()
    }



    func getRemovalReasons(subreddit: String, completion: @escaping ([String]) -> ()) {
        let url = URL(string: "https://oauth.reddit.com/r/\(subreddit)/api/v1/removal_reasons")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(String(describing: accessToken))", forHTTPHeaderField: "Authorization")

        // Make the API call here
        // For simplicity, assuming the removal reasons are just strings
        completion(["Reason 1", "Reason 2"])
    }

    func performModAction(subreddit: String, action: String, id: String, reason: String?, completion: @escaping (Bool) -> ()) {
        let url = URL(string: "https://oauth.reddit.com/r/\(subreddit)/api/\(action)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(String(describing: accessToken))", forHTTPHeaderField: "Authorization")
        
        var bodyData = "id=\(id)"
        if let reason = reason {
            bodyData += "&reason=\(reason)"
        }
        
        request.httpBody = bodyData.data(using: .utf8)

        // Make the API call here
        // For simplicity, assuming success for now
        completion(true)
    }
    
    // Method to refresh the access token using the refresh token
    func refreshTokenIfNeeded(completion: @escaping (Bool) -> Void) {
        guard let refreshToken = loadRefreshToken() else {
            completion(false)
            return
        }

        let tokenURL = URL(string: "https://www.reddit.com/api/v1/access_token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"

        let credentials = "bTHmGest7tBHTZ08b4XRag:CwN2HWikH1R0nQ_JAaPVOMrkPiS_AA".data(using: .utf8)!.base64EncodedString()
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "grant_type=refresh_token&refresh_token=\(refreshToken)"
        request.httpBody = body.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let data = data else {
                print("No data received")
                completion(false)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let newAccessToken = json["access_token"] as? String {
                    RedditAPI.shared.storeToken(newAccessToken)
                    RedditAPI.shared.setAccessToken(newAccessToken)
                    completion(true)
                } else {
                    print("Invalid JSON response")
                    completion(false)
                }
            } catch {
                print("JSON Parsing Error: \(error.localizedDescription)")
                completion(false)
            }
        }
        task.resume()
    }


    private func loadRefreshToken() -> String? {
        // Load the refresh token from Keychain
        // e.g., using KeychainAccess library
        let keychain = Keychain(service: "com.Stevereitz.LangeForReddit")
        return keychain["refreshToken"]
    }

     func storeToken(_ accessToken: String, refreshToken: String? = nil) {
         let keychain = Keychain(service: "com.Stevereitz.LangeForReddit")
         keychain["accessToken"] = accessToken
         print("accessToken attempted to be stored")
         if let refreshToken = refreshToken {
             keychain["refreshToken"] = refreshToken
         }
    }
}


