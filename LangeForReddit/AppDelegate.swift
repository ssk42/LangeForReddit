import UIKit


class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
//        print("URL Scheme Received: \(String(describing: url.scheme))")
        print("in App Delegate")
//        return true
        if url.scheme == "langeforreddit" {
            // Extract the authorization code
            print("url scheme is correct")
            if let code = extractCode(from: url) {
                print(code)
                // Exchange the code for a token
                exchangeCodeForToken(code)
            } else {
                print("code not found")
            }
            return true
        } else {
            print("STR: url scheme is bad is ")
        }
        print("returning false")
        return false
    }

     func extractCode(from url: URL) -> String? {
        // Extract the 'code' query parameter from the URL
        print("in extractCode")
        let urlComponents = URLComponents(string: url.absoluteString)
         
//        print(urlComponents)
        return urlComponents?.queryItems?.first(where: { $0.name == "code" })?.value
    }

     func exchangeCodeForToken(_ code: String) {
        print("in exchangeCodeForToken")
        // The URL for the Reddit token exchange endpoint
        let tokenURL = URL(string: "https://www.reddit.com/api/v1/access_token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        
        // Set up request headers (make sure to use your actual client ID and secret)
        let credentials = "bTHmGest7tBHTZ08b4XRag:CwN2HWikH1R0nQ_JAaPVOMrkPiS_AA".data(using: .utf8)!.base64EncodedString()
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Set up request body
        let body = "grant_type=authorization_code&code=\(code)&redirect_uri=langeforreddit://redirect"
        request.httpBody = body.data(using: .utf8)
        
        // Send the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                // Handle network errors
                print("Error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                // Handle cases where no data is returned
                print("No data received")
                return
            }

            do {
                // Parse the JSON response to get the access token
                print(data)
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let accessToken = json["access_token"] as? String {
                    print(json)
                    print("STR: accessToken set it is ",accessToken)
                    RedditAPI.shared.setAccessToken(accessToken)
                    // Store the token securely in the Keychain
//                    return true
                } else {
                    print("Invalid JSON response")
                }
            } catch {
                // Handle JSON parsing errors
                print("JSON Parsing Error: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
}
