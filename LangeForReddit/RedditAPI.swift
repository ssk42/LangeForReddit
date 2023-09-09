import Foundation

struct ModQueueResponse: Codable {
    struct Data: Codable {
        struct Children: Codable {
            struct Data: Codable {
                let id: String
            }
            let data: Data
        }
        let children: [Children]
    }
    let data: Data
}


class RedditAPI {
    let accessToken: String

    init(accessToken: String) {
        self.accessToken = ""
    }
    func getAccessToken( completion: @escaping (String?) -> ()) {
        guard let url = URL(string: "https://www.reddit.com/api/v1/access_token") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let bodyData = "grant_type=client_credentials&username=ssk42&password=5TeveTriesToGetKarma!"
        request.httpBody = bodyData.data(using: .utf8)

        let clientId = "bTHmGest7tBHTZ08b4XRag"
        let clientSecret = "CwN2HWikH1R0nQ_JAaPVOMrkPiS_AA"
        let loginData = String(format: "%@:%@", clientId, clientSecret).data(using: String.Encoding.utf8)!
        let base64LoginData = loginData.base64EncodedString()
        print("STR: base64 is \(base64LoginData)")
        request.setValue("Basic \(base64LoginData)", forHTTPHeaderField: "Authorization")
        print("STR: login header has been set ")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                print("STR: \(data)")
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject],
                       let fetchedToken = json["access_token"] as? String {
                        DispatchQueue.main.async {
                            let accessToken = fetchedToken
                            print("STR: \(fetchedToken)")
                            completion(fetchedToken)
                        }
                        print("STR:! \(self.accessToken)")
                    }
                } catch {
                    print("Error: \(error)")
                    completion(nil)
                }
            } else {
                print("No data received.")
                completion(nil)
            }
        }
        task.resume()
    }

    func getModQueue(subreddit: String,  completion: @escaping ([String]) -> ()) {
        print("STR: \(accessToken)")
        guard let url = URL(string: "https://oauth.reddit.com/r/PoliticalDiscussion/about/modqueue") else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(self.accessToken)", forHTTPHeaderField: "Authorization")
        print("Sending request to \(url)")

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
                let ids = decodedData.data.children.map { $0.data.id }
                print("STR: Decoded IDs: \(ids)")
                DispatchQueue.main.async {
                    completion(ids)
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
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        // Make the API call here
        // For simplicity, assuming the removal reasons are just strings
        completion(["Reason 1", "Reason 2"])
    }

    func performModAction(subreddit: String, action: String, id: String, reason: String?, completion: @escaping (Bool) -> ()) {
        let url = URL(string: "https://oauth.reddit.com/r/\(subreddit)/api/\(action)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        var bodyData = "id=\(id)"
        if let reason = reason {
            bodyData += "&reason=\(reason)"
        }
        
        request.httpBody = bodyData.data(using: .utf8)

        // Make the API call here
        // For simplicity, assuming success for now
        completion(true)
    }
}


