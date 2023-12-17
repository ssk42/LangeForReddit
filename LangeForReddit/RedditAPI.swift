import Foundation
import KeychainAccess

struct ModQueueResponse:  Codable {
    struct Data: Codable {
        struct Children: Codable {
            struct Data: Codable, Hashable {
                let id: String
                let title: String?
                let name: String
            }
            let data: Data
        }
        let children: [Children]
    }
    let data: Data
}

struct ModMailConversationDetail: Codable, Hashable {
    let isAuto: Bool
    let participant: Participant
    let objIds: [ObjId]
    let isRepliable: Bool
    let lastUserUpdate: String
    let isInternal: Bool
    let lastModUpdate: String?
    let authors: [Participant]
    let lastUpdated: String
    let participantSubreddit: [String: String?]
    let legacyFirstMessageId: String
    let state: Int
    let conversationType: String
    let lastUnread: String?
    let owner: Owner
    let subject: String
    let id: String
    let isHighlighted: Bool
    let numMessages: Int
    // Add other fields as necessary
}

struct Participant: Codable, Hashable {
    let name: String
    let isMod: Bool
}

struct ObjId: Codable, Hashable {
    let id: String
    let key: String
}

struct Owner: Codable, Hashable {
    let displayName: String
    let type: String
    let id: String
}

struct ModMailConversationsResponse: Codable {
    let conversations: [String: ModMailConversationDetail]
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
        request.addValue("Bearer \(accessToken ?? "")", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error getting removal reasons: \(error)")
                completion([])
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
               let data = data {
                // Parse the JSON and extract the reasons
                // For now, let's just print the data
                print(String(data: data, encoding: .utf8) ?? "Invalid response data")
                // Call the completion handler with the parsed reasons
                // Assuming the reasons are in the JSON under a key called "reasons"
            } else {
                print("Failed to get removal reasons, received HTTP response: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                completion([])
            }
        }
        task.resume()
    }


    func performModAction(subreddit: String, action: String, id: String, reason: String?, completion: @escaping (Bool) -> ()) {



            guard let url = URL(string: "https://oauth.reddit.com/r/\(subreddit)/api/\(action)") else {
                completion(false)
                return
            }

            // Setting up the request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("ChangeMeClient/0.1 by ssk42", forHTTPHeaderField: "User-Agent")
            request.addValue("Bearer \(self.accessToken ?? "")", forHTTPHeaderField: "Authorization")
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            // Constructing the body
            var parameters = "id=\(id)"
            if let reason = reason {
                parameters += "&reason=\(reason)"
            }
            parameters += "&uh=" // Including the `uh` parameter as empty
            let postData = parameters.data(using: .utf8)
            request.httpBody = postData
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    completion(false)
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Response Code: \(httpResponse.statusCode)")

                    if let responseString = String(data: data!, encoding: .utf8) {
                        print("Response String: \(responseString)")
                    }

                    if httpResponse.statusCode == 200 {
                        completion(true)
                    } else {
                        // Check the response body for error details
                        if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                            print("Response JSON: \(json)")
                        }
                        completion(false)
                    }
                }
            }
            task.resume()
        
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
    
    func fetchModhashFromListing(completion: @escaping (String?) -> Void) {
        // Example endpoint: user's comments. You can change this as needed.
        guard let url = URL(string: "https://oauth.reddit.com/user/ssk42/comments") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken ?? "")", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching listing: \(error.localizedDescription)")
                completion(nil)
                return
            }

            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let jsonData = json["data"] as? [String: Any],
               let modhash = jsonData["modhash"] as? String {
                completion(modhash)
            } else {
                print("Failed to fetch or parse modhash from listing.")
                completion(nil)
            }
        }
        task.resume()
    }
    
    func fetchModMailConversations(subreddit: String, limit: Int = 25, sort: String = "recent", completion: @escaping ([ModMailConversationDetail]?) -> Void) {
        guard let url = URL(string: "https://oauth.reddit.com/api/mod/conversations?entity=\(subreddit)&limit=\(limit)&sort=\(sort)") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url, timeoutInterval: Double.infinity)
        request.addValue("ChangeMeClient/0.1 by ssk42", forHTTPHeaderField: "User-Agent")
        request.addValue("Bearer \(self.accessToken ?? "")", forHTTPHeaderField: "Authorization") // Replace with your actual token

        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print("Error: \(String(describing: error))")
                completion(nil)
                return
            }

            do {
                let response = try JSONDecoder().decode(ModMailConversationsResponse.self, from: data)
                let conversations = Array(response.conversations.values)
                completion(conversations)
            } catch {
                print("Error decoding modmail conversations data: \(error)")
                completion(nil)
            }
        }

        task.resume()
    }







}


