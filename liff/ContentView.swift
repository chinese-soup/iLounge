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
    @State public var scrollProxy: ScrollViewProxy? = nil
    @State private var selectedEntry: String? = nil
    
    // Focus state to keep the text input field focused after sending a message
    @FocusState private var textFieldIsFocused: Bool
    
    //@ObservedObject var webSocketManager = WebSocketManager(password: "")
    
    @State private var messageToSend = ""
    
    // Settings using AppStorage
    @AppStorage("loungeHostname") private var hostnameSetting: String = ""
    @AppStorage("loungePort") private var portSetting: String = "8080"
    @AppStorage("loungeUseSsl") private var useSslSetting: Bool = false
    
    // SocketIO manager, needs to be ObservedObject so that it doesn't get destroyed during the lifetime of the app
    @ObservedObject var socketManager: SocketManagerWrapper //= SocketManagerWrapper(socketURL: "ws://127.0.0.2:9000/")
    
    // View's constructor
    init() {
        print("Hello from init()")
        //configureSocketIO()
        
        self.socketManager = SocketManagerWrapper(socketURL: "ws://127.0.0.2:9000/")
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    ScrollViewReader { proxy in
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(socketManager.messages, id: \.self) { msg in
                                Text(msg).id(msg) // id here is important for the scroll proxy to work apparently
                                    .padding(.horizontal)
                                    .onTapGesture {
                                        selectedEntry = msg
                                        let pasteboard = UIPasteboard.general
                                        pasteboard.string = "Hello, world!"
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
                    /*List(socketManager.messages, id: \.self) { message in
                     Text(message)
                     }*/
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
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
            .navigationBarItems(trailing:
                                    Button(action: {
                isSettingsVisible.toggle()
            }) {
                Image(systemName: "gear")
            }
                                
            )
            // TODO: Remove this stuff
            // TODO: Probably make the settings sheet not be a sheet?
            // TODO: ^ Dunno navigation instead? We shall see about it.
            /*.sheet(isPresented: $isTestViewVisible) {
             TestView(isTestViewVisible: $isTestViewVisible)
             }*/
            .sheet(isPresented: $isSettingsVisible) {
                SettingsView(isSettingsVisible: $isSettingsVisible).onDisappear() {
                    // TODO: When we close settings we scroll down, because the keyboard might screw up the scroll position, lol :|
                    scrollProxy?.scrollTo(socketManager.messages.last, anchor: .bottom)
                }
            }.navigationTitle("iLounge")
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
    
    func configureSocketIO() {
        print("Configure SocketIO called...")
        var proto = "ws"
        if useSslSetting == true {
            proto = "wss"
        }
        
        let loungeUrlFormatted =  "\(proto)://\(hostnameSetting)/\(portSetting)"
        print("The Lounge URL is \(loungeUrlFormatted)")
        
        //socketMan = SocketManager(socketURL: URL(string: hostnameSetting)!)
        
        /* = SocketManager(socketURL: URL(string: "ws://127.0.0.2:9000/")!, config: [.log(true)])
        
        socketMan?.defaultSocket.on(clientEvent: .connect) { _, _ in
                   print("Socket connected")
               }
               
        socketMan?.defaultSocket.on("message") { data, ack in
                   if let message = data.first as? String {
                       entries.append(message)
                   }
               }
        socketMan?.defaultSocket.on("error") { data, ack in
            if let error = data.first as? String {
                print("Socket error: \(error)")
            }
        }
               
        socketMan?.connect()*/
    }
    
}

struct TestView: View {
    @Binding var isTestViewVisible: Bool
    let baseText = "apple banana pear orange lemon"
    let baseUrl = "https://github.com/search/repositories?q="
    
    var body: some View {
        /*let clickableText = baseText.split(separator: " ").map{ "[\($0)](\(baseUrl)\($0))" }
        ForEach(clickableText, id: \.self) { txt in
            let attributedString = try! AttributedString(markdown: txt)
            Text(attributedString)
                .environment(\.openURL, OpenURLAction { url in
                    print("---> link actioned: \(txt.split(separator: "=").last)" )
                    return .systemAction
                })
        }*/
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
    }
}

struct SettingsView: View {
    @Binding var isSettingsVisible: Bool
    // Connection settings
    @AppStorage("loungeHostname") private var hostnameSetting: String = ""
    @AppStorage("loungePort") private var portSetting: String = "8080" // TODO: This is a String because Integer hated me, look into it again
    @AppStorage("loungeUseSsl") private var useSslSetting: Bool = false
    // Display settings
    @AppStorage("loungeShowTimestamps") private var showTimestampsSetting: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Connection Settings")) {
                    HStack {
                        Text("Hostname")
                        Spacer()
                        TextField("Enter the hostname of your The Lounge instance", text: $hostnameSetting)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Port")
                        Spacer()
                        TextField("Enter the port of your The Lounge instance", text: $portSetting)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Use SSL")
                        Spacer()
                        Toggle("", isOn: $useSslSetting)
                    }
                }
                
                Section(header: Text("Display Settings")) {
                    HStack {
                        Text("Timestamp format")
                        Spacer()
                        TextField("hh:mm:ss", text: $hostnameSetting) // TODO: FIXME actual binding
                    }
                    HStack {
                        Text("Show timestamps")
                        Spacer()
                        Toggle("", isOn: $showTimestampsSetting)
                    }
                    HStack {
                        Text("Show join/part")
                        Spacer()
                        Toggle("", isOn: $showTimestampsSetting) // TODO: FIXME actual binding
                    }
                }
            }.listStyle(GroupedListStyle())  
            .navigationBarTitle("Settings")
            .navigationBarItems(trailing: Button(action: {
                isSettingsVisible.toggle()
                saveSettings()
            }) {
                Text("Done")
            })
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(hostnameSetting, forKey: "loungeHostname")
        UserDefaults.standard.set(portSetting, forKey: "loungePort")
        UserDefaults.standard.set(useSslSetting, forKey: "loungeUseSsl")
        
        UserDefaults.standard.set(showTimestampsSetting, forKey: "loungeShowTimestamps")
    }
    
}



class SocketManagerWrapper: ObservableObject {
    @Published var messages: [String] = [] // Make this into a Message Model
    // OR well, make everything into models, really :--)
    // E.g. buffers (servers / channels)
    // E.g. NickList etc.
    //
    var socket: SocketManager?
    @AppStorage("loungeHostname") private var hostnameSetting: String = ""
    @AppStorage("loungePort") private var portSetting: String = "8080"
    @AppStorage("loungeUseSsl") private var useSslSetting: Bool = false
    
    init(socketURL: String) {
        var proto = "ws"
        if useSslSetting {
            proto = "wss"
        }
        let formattedSocketURL = "\(proto)://\(hostnameSetting):\(portSetting)/"
        print("URL is \(formattedSocketURL)")
        
        socket = SocketManager(socketURL: URL(string: formattedSocketURL)!, config: [.log(false), .forceWebsockets(true)])
        configureSocket()
    }
    
    func sendMessage(message: String, channel_id: Int = 2) {
        // "input",
        //{"target": chan_id, "text": "ahojky uz jsem tady taky!!!"}
        let msgToSend = ["target": channel_id, "text": message] as [String : Any]
        socket?.defaultSocket.emit("input", msgToSend)
    }
    
    func parseTimestamp(isoDate: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = dateFormatter.date(from:isoDate) {
            return date
        } else {
            return nil
        }
    }
    
    private func configureSocket() {
        socket?.defaultSocket.on(clientEvent: .connect) { data, ack in
            print("Socket connected", data, ack)
           
        }
        
        socket?.defaultSocket.on("msg") { [self] data, ack in
            if let message = data.first as? Dictionary<String,Any>,
               let msg = message["msg"] as? Dictionary<String,Any> {
                let messageText = msg["text"] as! String
                let messageTs = msg["time"] as! String
                let messageFrom = msg["from"] as! Dictionary<String, Any>
                let messageNick = messageFrom["nick"] as! String
                let messageFinal = "\(messageTs) <\(messageNick)> \(messageText)"
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
        // Using a shorthand parameter name for closures
        //socket?.defaultSocket.onAny {print("Got event: \($0.event), with items: \($0.items)")}
        
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
                                    // Text
                                    let messageText = message["text"] as! String
                                    
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
                                    let messageFrom = message["from"] as! Dictionary<String, Any>
                                    let messageNick = messageFrom["nick"] as! String
                                    let messageFinal = "\(messageTs) <\(messageNick)> \(messageText)"
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
                self.messages.append(String(describing:data))
            }
        }
        
        socket?.defaultSocket.connect()
        
    }
}

#Preview {
    ContentView()
}
