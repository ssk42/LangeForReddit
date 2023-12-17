import SwiftUI

struct ContentView: View {
    @State var modItems: [ModQueueResponse.Data.Children.Data] = []
    @State var subreddit: String = "Mod"
    @State var selectedReason: String?
    @State private var modMailConversations: [ModMailConversationDetail] = []
//    @State var accessToken: String?

    var body: some View {
//        if (RedditAPI.shared.accessToken == nil) {
            Button("Login with Reddit") {
                startRedditOAuthFlow()
            }
//        } else{
        VStack{
            TextField("Enter subreddit", text: $subreddit, onCommit: {
                // Trigger loading of Mod Queue and Mod Mail
                loadModQueue()
                loadModMail()
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
            TabView{
                NavigationView {
                    VStack {
                        List(modItems, id: \.id) { item in
                            Text(item.title ?? "No title")
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        approveItem(item)
                                    } label: {
                                        Label("Approve", systemImage: "checkmark.circle")
                                    }
                                    .tint(.green)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteItem(item)
                                    } label: {
                                        Label("Delete", systemImage: "trash.circle")
                                    }
                                }
                        }
//                        ForEach(modItems, id: \.self) { item in
//                            HStack {
//                                Text(item.title ?? "something")
//                                Spacer()
//                                Button("Approve") {
//                                    print("Approve button pressed")
//                                    RedditAPI.shared.performModAction(subreddit: subreddit, action: "approve", id: item.name, reason: nil) { success in
//                                        if success {
//                                            print("Approved item with ID: \(item.name)")
//                                        }
//                                    }
//                                }
//                                .foregroundColor(.green)
//                                .buttonStyle(PlainButtonStyle())
//                                .padding(.horizontal) // Add some padding
//                                Button("Remove") {
//                                    print("Remove Button pressed")
//                                    RedditAPI.shared.performModAction(subreddit: subreddit, action: "remove", id: item.name, reason: nil) { success in
//                                        if success {
//                                            print("Removed item with ID: \(item.name)")
//                                        }
//                                    } // TODO: add removal reasons (aka rules, I guess??)
//                                }
//                                .foregroundColor(.red)
//                                .buttonStyle(PlainButtonStyle())
//                                .padding(.horizontal)
//                            }
//                        }
                    }
//                    .navigationTitle("Reddit Mod Queue")
                } // end of NavView
                .tabItem {
                    Label("Mod Queue", systemImage: "list.dash")
                }
                ModMailView(modMailConversations: $modMailConversations)
                    .tabItem {
                        Label("Mod Mail", systemImage: "envelope")
                    }
            }
            .onOpenURL(perform: { url in
                handleURL(url)
            })
        }
    }
    func startRedditOAuthFlow() {
        let redditAuthURL = "https://www.reddit.com/api/v1/authorize"
        let clientId = "bTHmGest7tBHTZ08b4XRag"
        let redirectUri = "http://localhost:8000/redirect"
        let responseType = "code"
        let state = "RANDOM_STATE_STRING"
        let scope = "read,modposts,modmail"

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
    private func loadModQueue(){
        print("STR: accessToken at get ModQueue is \(String(describing: RedditAPI.shared.accessToken))")
        if !subreddit.isEmpty {
            RedditAPI.shared.getModQueue(subreddit: subreddit) { items in
                self.modItems = items
            }
        }
    }
    private func loadModMail() {
        RedditAPI.shared.fetchModMailConversations(subreddit: subreddit) { conversations in
            if let conversations = conversations {
                DispatchQueue.main.async {
                    self.modMailConversations = conversations
                }
            } else {
                // Handle the error or empty state
            }
        }
    }
    private func approveItem(_ item: ModQueueResponse.Data.Children.Data) {
        print("Approve button pressed")
        RedditAPI.shared.performModAction(subreddit: subreddit, action: "approve", id: item.name, reason: nil) { success in
            if success {
                print("Approved item with ID: \(item.name)")
            }
        }
    }
    private func deleteItem(_ item: ModQueueResponse.Data.Children.Data){
        print("Remove Button pressed")
        RedditAPI.shared.performModAction(subreddit: subreddit, action: "remove", id: item.name, reason: nil) { success in
            if success {
                print("Removed item with ID: \(item.name)")
            }
        } // TODO: add removal reasons (aka rules, I guess??)
    }
}
struct ModMailView: View {
    @Binding var modMailConversations: [ModMailConversationDetail]

    var body: some View {
        List(modMailConversations, id: \.id) { conversation in
            VStack(alignment: .leading) {
                Text(conversation.subject).font(.headline)
                Text("Last update: \(conversation.lastUserUpdate)").font(.subheadline)
                // Display other fields as needed
            }
        }
    }
}



