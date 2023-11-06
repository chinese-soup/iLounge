//
//  ContentView.swift
//  liff
//
//  Created by Jakub Mach on 03.11.2023.
//

import SwiftUI
import Starscream
import BinarySwift
import SocketIO
import CoreData

struct ContentView: View {
    // TODO: Clean up these
    @State private var messageInput = ""
    @State private var isSettingsVisible = false
    @State private var isTestViewVisible = false
    @State private var isPreviewViewVisible = false
    @State public var scrollProxy: ScrollViewProxy? = nil
    @State private var selectedEntry: String? = nil
    
    @State private var currentPreviewURL = "https://picsum.photos/600"
    
    // Focus state to keep the text input field focused after sending a message
    @FocusState private var textFieldIsFocused: Bool
    
    //@ObservedObject var webSocketManager = WebSocketManager(password: "")
    
    @State private var messageToSend = ""
    
    // Settings using AppStorage
    @AppStorage("loungeHostname") private var hostnameSetting: String = "" // TODO: Unused here?
    @AppStorage("loungePort") private var portSetting: String = "8080" // TODO: Unused here?
    @AppStorage("loungeUseSsl") private var useSslSetting: Bool = false // TODO: Unused here?
    
    @AppStorage("loungeUseMonospaceFont") private var useMonospaceFont: Bool = false
    
    // SocketIO manager, needs to be ObservedObject so that it doesn't get destroyed during the lifetime of the app
    @ObservedObject var socketManager: SocketManagerWrapper //= SocketManagerWrapper(socketURL: "ws://127.0.0.2:9000/")
    
    // View's constructor
    init() {
        print("Hello from init()")
        //configureSocketIO()
        self.socketManager = SocketManagerWrapper(socketURL: "ws://127.0.0.2:9000/")
    }
    
    func handleUserClickedLink(url: URL) {
        if isImage(text: url.absoluteString) {
            currentPreviewURL = url.absoluteString
            isPreviewViewVisible.toggle()
        }
        else {
            UIApplication.shared.open(url)
        }
    }
    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack {
                    ScrollView {
                        ScrollViewReader { proxy in
                            VStack(alignment: .leading, spacing: 5) {
                                ForEach(socketManager.messages, id: \.self) { msg in
                                    Text(.init(msg)).id(msg) // id here is important for the scroll proxy to work apparently
                                        .padding(.horizontal)
                                        .font(.system(.body, design: useMonospaceFont == true ? .monospaced : .default))
                                        //.textSelection(.enabled)
                                        .environment(\.openURL, OpenURLAction { url in
                                            handleUserClickedLink(url: url)
                                            return .handled
                                        })
                                        .onTapGesture {
                                            selectedEntry = msg
                                            let pasteboard = UIPasteboard.general
                                            pasteboard.string = msg
                                           
                                        }
                                        .contextMenu {
                                            Button {
                                            } label: {
                                                Label("Copy to clipboard with timestamp", systemImage: "doc.on.doc.fill")
                                            }
                                            Button {
                                            } label: {
                                                Label("Copy to clipboard without timestamp", systemImage: "doc.on.doc")
                                            }
                                        }
                                }
                            }
                            .onAppear {
                                scrollProxy = proxy
                            }
                            .onChange(of: socketManager.messages) {
                                withAnimation {
                                    scrollProxy?.scrollTo(socketManager.messages.last, anchor: .bottom)
                                }
                            }
                        }
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    HStack {
                        TextField("Type a message", text: $messageInput, onCommit: {
                            DispatchQueue.main.async {
                                sendMessage()
                            }
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .focused($textFieldIsFocused)
                        
                        Button(action: {
                            sendMessage()
                        }) {
                            Image(systemName: "arrowshape.turn.up.right.fill")
                        }
                        .padding(.trailing)
                    }
                    .padding(.bottom)
                }
                .navigationBarItems(
                    leading: Button(action: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            isPreviewViewVisible.toggle()
                        }
                    }) {
                        Image(systemName: "menucard") //sidebar.left
                    },
                    
                    trailing: Button(action: {
                        isSettingsVisible.toggle()
                    }) {
                        Image(systemName: "gear")
                    }
                    
                )
                // TODO: Remove this stuff
                // TODO: Probably make the settings sheet not be a sheet?
                // TODO: ^ Dunno navigation instead? We shall see about it.
                .sheet(isPresented: $isPreviewViewVisible){
                    PreviewView(isPreviewViewVisible: $isPreviewViewVisible, imageURL: $currentPreviewURL)
                }
                .sheet(isPresented: $isTestViewVisible) {
                    TestView(isTestViewVisible: $isTestViewVisible)
                }
                .sheet(isPresented: $isSettingsVisible) {
                    SettingsView(isSettingsVisible: $isSettingsVisible).onDisappear() {
                        // TODO: When we close settings we scroll down, because the keyboard might screw up the scroll position, lol :|
                        scrollProxy?.scrollTo(socketManager.messages.last, anchor: .bottom)
                    }
                }.navigationTitle("iLounge")
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    func sendMessage() {
        if !messageInput.isEmpty {
            socketManager.sendMessage(message: messageInput, channel_id: 2)
            messageInput = ""
            scrollProxy?.scrollTo(socketManager.messages.count - 1, anchor: .bottom)
        }
        else
        {
            print("isTestViewVisible = \(isTestViewVisible)")
            isTestViewVisible.toggle()
        }
        textFieldIsFocused = true
    }
    
    func findFirstLinkRange(in text: String) -> Range<String.Index>? {
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            if let match = detector.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {
                if let range = Range(match.range, in: text) {
                    return range
                }
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
        return nil
    }
    
    func isImage(text: String) -> Bool {
        /* A dumb way to check if URL could be an image to open in a preview instead of the web browser */
        let letImagePattern = #"(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*\.(?:jpg|jpeg|gif|png))(?:\?([^#]*))?(?:#(.*))?"#
        if text.range(of: letImagePattern, options: .regularExpression) != nil {
            return true
        }
        return false
    }
}

struct TestView: View {
    @Binding var isTestViewVisible: Bool
    private let width = UIScreen.main.bounds.width - 100
    let baseText = "apple http://google.com pear orange lemon"
    let baseUrl = "https://github.com/search/repositories?q="
    
    var body: some View {
        
        let clickableText = baseText.split(separator: " ").map{ "[\($0)](\(baseUrl)\($0))" }
        ForEach(clickableText, id: \.self) { txt in
            let attributedString = try! AttributedString(markdown: txt)
            Text(attributedString)
                .environment(\.openURL, OpenURLAction { url in
                    print("---> link actioned: \(String(describing: txt.split(separator: "=").last))" )
                    return .systemAction
                })
        }
        ZStack {
                    Color.gray.opacity(0.5)
                        .onTapGesture {
                            withAnimation {
                                isTestViewVisible.toggle()
                            }
                        }

                    VStack {
                        Text("Side Drawer")
                            .font(.largeTitle)
                            .padding()

                        Spacer()
                    }
                }
        
        VStack {
            Text(.init("Ahoj [blabla](https://google.com)"))
            Color.blue
        }
        .frame(width: self.width)
    }
}

class SocketManagerWrapper: ObservableObject {
    @Published var messages: [String] = [] // TODO: Make this into a proper Message Model
    // TODO: OR well, make everything into models, really :--)
    // TODO: E.g. buffers (servers / channels)
    // TODO: E.g. NickList etc.
    //
    var socket: SocketManager?
    @AppStorage("loungeHostname") private var hostnameSetting: String = ""
    @AppStorage("loungePort") private var portSetting: String = "8080"
    @AppStorage("loungeUseSsl") private var useSslSetting: Bool = false
    
    init(socketURL: String) {
        var proto = "ws"
        if useSslSetting {
            proto = "wss"
            proto = "https"
        }
        if let formattedSocketURL = URL(string:"\(proto)://\(hostnameSetting):\(portSetting)/") {
            print("URL is \(formattedSocketURL)")
            socket = SocketManager(socketURL: formattedSocketURL, config: [.log(false), .forceWebsockets(true)])
            DispatchQueue.main.async { [self] in
                configureSocket()
            }
        }
        else {
            print("SOCKET FAILED because WRONG HOSTNAME") // TODO: uhh
            self.messages.append("Socket connection failed, wrong hostname probs bro lol") // TODO: ^
        }
        
        
    }
    
    func sendMessage(message: String, channel_id: Int = 2) {
        // TODO: Un-hardcode target, load from the buffer model that we want to send to the "current buffer"
        let msgToSend = ["target": channel_id, "text": message] as [String : Any]
        socket?.defaultSocket.emit("input", msgToSend)
    }
    
    func parseTimestamp(isoDate: String) -> Date? {
        // TODO: Move out of here to some utils class or something
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = dateFormatter.date(from:isoDate) {
            return date
        } else {
            return nil
        }
    }
    
    func replaceLinksWithMarkdownHyperlinks(origMsgText: String) -> String {
        let urlPattern = #"((?:(?:https?|ftp)://)?[\w/\-?=%.]+\.[\w/\-&?=%.]+)"#
        let messageTextWithMarkdown = origMsgText.replacingOccurrences(of: urlPattern, with: "[$1]($1)", options: .regularExpression)
        print(messageTextWithMarkdown)
        
        return messageTextWithMarkdown
    }
    
    private func configureSocket() {
        
        // TODO: Use for debugging to get all the events handled
        //socket?.defaultSocket.onAny {print("Got event: \($0.event), with items: \($0.items)")}
        socket?.defaultSocket.on(clientEvent: .statusChange) { data, ack in
            print("Status change", data, ack)
            
            self.messages.append("Status: \(data)")
        }
        
        socket?.defaultSocket.on(clientEvent: .connect) { data, ack in
            print("Socket connected", data, ack)
        }
        
        socket?.defaultSocket.on("msg") { [self] data, ack in
            if let message = data.first as? Dictionary<String,Any>,
               let msg = message["msg"] as? Dictionary<String,Any> {
                // TODO: ID - good for the model I wanna make later, I guess :-)
                //let _ = message["id"] as! Int // except it isn't in the "msg" message? lol
                
                // Text
                let messageText = msg["text"] as! String
                let messageTextWithMarkdown = replaceLinksWithMarkdownHyperlinks(origMsgText: messageText)
                
                // Timestamp
                let messageTsStr = msg["time"] as! String
                var messageTs = messageTsStr
                // If we can parse the timestamp, change it to correct format
                if let messageDateUTC = self.parseTimestamp(isoDate: messageTsStr) {
                    let outputFormatter = DateFormatter()
                    outputFormatter.dateFormat = "HH:mm:ss"
                    messageTs = outputFormatter.string(from: messageDateUTC)
                }
                
                // From
                var messageFinal: String;
                if let messageFrom = msg["from"] as? Dictionary<String, Any>,
                   let messageNick = messageFrom["nick"] as? String {
                    messageFinal = "\(messageTs) <\(messageNick)> \(messageTextWithMarkdown)"
                }
                else {
                    messageFinal = "\(messageTs) <SYSTEM> \(messageTextWithMarkdown)" // TODO: This is wrong
                }
                
                // Final message format
                // TODO: Proper models
                self.messages.append(messageFinal)
            }
        }
        
        socket?.defaultSocket.on("message") { [self] data, ack in
            print("message \(data)")
            if let message = data.first as? String {
                self.messages.append(message)
                self.messages.append(String(describing:data))
            }
        }
        
        socket?.defaultSocket.on("connect") { [self] data, ack in
            print("message \(data)")
            if let message = data.first as? String {
                self.messages.append(message)
                self.messages.append(String(describing:data))
            }
        }
        
        socket?.defaultSocket.on("init") {data, ack in
            //print("INIT \(String(describing:data))")
            //let typeof = type(of: data)
            
            if let message = data.first as? Dictionary<String,Any>,
               let networks = message["networks"] as? Array<Dictionary<String,Any>> {
                for network in networks {
                    if let channels = network["channels"] as? Array<Dictionary<String, Any>> {
                        for channel in channels {
                            self.messages.append(String(describing: channel["name"]))
                            if let messages = channel["messages"] as? Array<Dictionary<String, Any>> {
                                for message in messages {
                                    // TODO: ID - good for the future model I guess :-)
                                    let _ = message["id"] as! Int
                                    
                                    // Text
                                    let messageText = message["text"] as! String
                                    let messageTextWithMarkdown = self.replaceLinksWithMarkdownHyperlinks(origMsgText: messageText)
                                    
                                    // Timestamp
                                    let messageTsStr = message["time"] as! String
                                    var messageTs = messageTsStr
                                    // If we can parse the timestamp, change it to correct format
                                    if let messageDateUTC = self.parseTimestamp(isoDate: messageTsStr) {
                                        let outputFormatter = DateFormatter()
                                        outputFormatter.dateFormat = "HH:mm:ss"
                                        messageTs = outputFormatter.string(from: messageDateUTC)
                                    }
                                    
                                    // From
                                    var messageFinal: String;
                                    if let messageFrom = message["from"] as? Dictionary<String, Any>,
                                       let messageNick = messageFrom["nick"] as? String {
                                        messageFinal = "\(messageTs) <\(messageNick)> \(messageTextWithMarkdown)"
                                    }
                                    else {
                                        messageFinal = "\(messageTs) <SYSTEM> \(messageTextWithMarkdown)" // TODO: This is wrong
                                    }
                                    
                                    // Final message format
                                    // TODO: Proper models
                                    self.messages.append(messageFinal)
                                }
                            }
                        }
                    }
                }
            }
        }
            
        socket?.defaultSocket.on("auth:start") { [self] data, ack in
            // we got  auth start's exgon gonan give it to em
            print("AUTH START BRo message \(String(describing:data))")
            let swiftDict: [String: String] = ["user": "polivka", "password": "asdf"]
            
            socket?.defaultSocket.emit("auth:perform", swiftDict)
            
            if let message = data.first as? String {
                print("auth:start \(message)")
                self.messages.append(String(describing:message))
            }
        }
        
        socket?.defaultSocket.connect()
        
    }
}

#Preview {
    ContentView()
}
