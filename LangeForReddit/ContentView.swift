import SwiftUI

struct ContentView: View {
    let redditAPI = RedditAPI(accessToken: "")
    @State var modItems: [String] = []
    @State var subreddit: String = "PoliticalDiscussion"
    @State var selectedReason: String?
    @State var accessToken: String?

    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter subreddit", text: $subreddit)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Get Access Token") {
                    redditAPI.getAccessToken() { token in
                        self.accessToken = token
                        print("STR: token is \(token)")
                    }
                }
                
                Button("Load Mod Queue") {
                    if !subreddit.isEmpty {
                        redditAPI.getModQueue(subreddit: subreddit) { items in
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
                        Text(item)
                        Spacer()
                        Button("Approve") {
                            redditAPI.performModAction(subreddit: subreddit, action: "approve", id: item, reason: nil) { success in
                                if success {
                                    print("Approved")
                                }
                            }
                        }
                        .foregroundColor(.green)
                        
                        Button("Remove") {
                            redditAPI.getRemovalReasons(subreddit: subreddit) { reasons in
                                // For this example, we just select the first reason.
                                // In a real app, you would present these to the user for selection.
                                if let reason = reasons.first {
                                    redditAPI.performModAction(subreddit: subreddit, action: "remove", id: item, reason: reason) { success in
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
                self.redditAPI.getAccessToken() { token in
                    self.accessToken = token
                }
                print(accessToken)
                self.redditAPI.getModQueue(subreddit: "PoliticalDiscussion") { items in
                    self.modItems = items
                }
            }
            .navigationTitle("Reddit Mod Queue")
        }
    }
}
