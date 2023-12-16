import SwiftUI

struct ContentView: View {
    @State var modItems: [ModQueueResponse.Data.Children.Data] = []
    @State var subreddit: String = "PoliticalDiscussion"
    @State var selectedReason: String?
//    @State var accessToken: String?

    var body: some View {
        Button("Login with Reddit") {
            startRedditOAuthFlow()
        }
        Button("Test Open URL") {
            let testURL = URL(string: "langeforreddit://authorize_callback?code=test")!
            UIApplication.shared.open(testURL)
        }
        .padding()
        TabView{
            NavigationView {
                VStack {
                    TextField("Enter subreddit", text: $subreddit)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button("Load Mod Queue") {
                        print("STR: accessToken at get ModQueue is \(String(describing: RedditAPI.shared.accessToken))")
                        if !subreddit.isEmpty {
                            RedditAPI.shared.getModQueue(subreddit: subreddit) { items in
                                self.modItems = items
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    List(modItems, id: \.self) { item in
                        HStack {
                            Text(item.title ?? "something")
                            Spacer()
                            Button("Approve") {
                                print("Approve button pressed")
                                RedditAPI.shared.performModAction(subreddit: subreddit, action: "approve", id: item.id, reason: nil) { success in
                                    if success {
                                        print("Approved")
                                    }
                                }
                            }
                            .foregroundColor(.green)
                            
                            Button("Remove") {
                                print("Remove Button pressed")
                                RedditAPI.shared.getRemovalReasons(subreddit: subreddit) { reasons in
                                    // For this example, we just select the first reason.
                                    // In a real app, you would present these to the user for selection.
                                    if let reason = reasons.first {
                                        RedditAPI.shared.performModAction(subreddit: subreddit, action: "remove", id: item.id, reason: reason) { success in
                                            if success {
                                                print("Removed with reason: \(reason)")
                                            }
                                        }
                                    }
                                }
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
                .onAppear() {
                    print("STR:at at OnAppear is \(String(describing: RedditAPI.shared.accessToken))")
                }
                .navigationTitle("Reddit Mod Queue")
            } // end of NavView
            .tabItem {
                Label("Mod Queue", systemImage: "list.dash")
            }
            ModMailView()
                .tabItem {
                    Label("Mod Mail", systemImage: "envelope")
                }
        }
        .onOpenURL(perform: { url in
            handleURL(url)
        })
    }
    func startRedditOAuthFlow() {
        let redditAuthURL = "https://www.reddit.com/api/v1/authorize"
        let clientId = "bTHmGest7tBHTZ08b4XRag"
        let redirectUri = "http://localhost:8000/redirect"
        let responseType = "code"
        let state = "RANDOM_STATE_STRING"
        let scope = "read"

        let urlString = "\(redditAuthURL)?client_id=\(clientId)&response_type=\(responseType)&state=\(state)&redirect_uri=\(redirectUri)&duration=permanent&scope=\(scope)"
        if let url = URL(string: urlString) {
            print("Opening URL: \(url)")

            UIApplication.shared.open(url)
        }
    }
    private func handleURL(_ url: URL) {
        // Extract the authorization code from the URL
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems,
              let code = queryItems.first(where: { $0.name == "code" })?.value else {
            print("Failed to extract authorization code from URL")
            return
        }
        
        print("Authorization code: \(code)")
        exchangeCodeForToken(code)
        // Proceed with your OAuth token exchange process
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
       let body = "grant_type=authorization_code&code=\(code)&redirect_uri=http://localhost:8000/redirect"
       request.httpBody = body.data(using: .utf8)
       
        print(request)
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
               if let httpResponse = response as? HTTPURLResponse {
                   print("HTTP Response Code: \(httpResponse.statusCode)")
               }
               if let responseString = String(data: data, encoding: .utf8) {
                   print("Response String: \(responseString)")
               }

               if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let accessToken = json["access_token"] as? String {
//                   print(json)
//                   print("STR: accessToken set it is ",accessToken)
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
struct ModMailView: View {
    // Your ModMail logic can go here
    var body: some View {
        Text("ModMail Content")
    }
}
