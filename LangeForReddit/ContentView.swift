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
                                RedditAPI.shared.performModAction(subreddit: subreddit, action: "approve", id: item.id, reason: nil) { success in
                                    if success {
                                        print("Approved")
                                    }
                                }
                            }
                            .foregroundColor(.green)
                            
                            Button("Remove") {
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
}
struct ModMailView: View {
    // Your ModMail logic can go here
    var body: some View {
        Text("ModMail Content")
    }
}
