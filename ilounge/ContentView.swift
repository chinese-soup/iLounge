//
//  ContentView.swift
//  ilounge
//
//  Created by Jakub Mach on 03.11.2023.
//

import SwiftUI
import Starscream
import SocketIO
import CoreData


struct ContentView: View {
    // TODO: Clean up these
    @State private var messageInput = ""

    @State private var scrolledID: Int?
    @State private var contentHeight: CGFloat = .zero
    @State private var scrollViewHeight: CGFloat = .zero

    @State private var lastMessageVisible: Bool = false

    // Visibility
    @State private var isSettingsVisible = false
    @State private var isTestViewVisible = false
    @State private var isPreviewViewVisible = false
    @State private var isBufferViewVisible = false
    @FocusState private var textFieldIsFocused: Bool

    @State public var scrollProxy: ScrollViewProxy? = nil
    @State private var selectedEntry: String? = nil

    // PreviewView Bidnings
    @State private var currentPreviewURL = ""
    @State private var currentPreviewIsVideo = false

    // Focus state to keep the text input field focused after send
    //@ObservedObject var webSocketManager = WebSocketManager(password: "")
    
    @State private var messageToSend = ""
    
    // Settings using AppStorage
    @AppStorage("loungeHostname") private var hostnameSetting: String = "" // TODO: Unused here?
    @AppStorage("loungePort") private var portSetting: String = "8080" // TODO: Unused here?
    @AppStorage("loungeUseSsl") private var useSslSetting: Bool = false // TODO: Unused here?

    // Display settings
    @AppStorage("loungeShowTimestamps") private var showTimestampsSetting: Bool = true
    @AppStorage("loungeTimestampFormat") private var timestampFormatSetting: String = "hh:mm:ss"

    @AppStorage("loungeUseMonospaceFont") private var useMonospaceFont: Bool = false
    @AppStorage("loungeShowJoinPart") private var showJoinPartSetting: Bool = true

    @AppStorage("loungeNickLength") private var nickLengthSetting: Int = 0


    // SocketIO manager, needs to be ObservedObject so that it doesn't get destroyed during the lifetime of the app
    @ObservedObject var socketManager: SocketManagerWrapper

    // Check whether we are in dark mode or light mode
    @Environment(\.colorScheme) var colorScheme

    // View's constructor
    init() {
        print("Hello from init()")
        self.socketManager = SocketManagerWrapper()
    }

    func getNicknameColor(nickname: String) -> Color {
        // The hash func is the same as in The Lounge
        // to keep the colors for nicknames consistent with the webapp

        // TODO: Consider caching the color in the msgfrom struct
        var hash = 0

        for c in nickname.utf8 {
            hash += Int(c)
        }
        hash = hash % 32

        if colorScheme == .dark {
            if hash < Color.nickColorsDark.count {
                return Color.nickColorsDark[hash]
            } else {
                return Color(.white)
            }
        } else {
            if hash < Color.nickColorsLight.count {
                return Color.nickColorsLight[hash]
            } else {
                return Color(.darkGray)
            }
        }
    }

    func truncateNickname(origNickname: String) -> String {
        if nickLengthSetting == 0 {
            return origNickname
        }
        return origNickname.count > nickLengthSetting ? String(origNickname.prefix(nickLengthSetting)) : origNickname
    }

    func formatTimestamp(parsedDate: Date) -> String {
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = timestampFormatSetting
        return outputFormatter.string(from: parsedDate)
    }

    var bottomField: some View {
        HStack {
            Button(action: {
                print("Tab complete")
            }) {
                Image(systemName: "arrow.right.to.line")
            }.padding(.leading)

            TextField("Type a message", text: $messageInput, onCommit: {
                textFieldIsFocused = true
            }) // TextEditor for multiline, but then I can't send lol
                .onSubmit {
                    DispatchQueue.main.async {
                        sendMessage()
                    }
                }
                .frame(maxHeight: 40)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                // .padding(.trailing) // TODO: Leave padding only on Buttons around the Textbox?
                .focused($textFieldIsFocused)
            Button(action: {
                textFieldIsFocused = true
                sendMessage()
            }) {
                Image(systemName: "arrowshape.turn.up.right.fill")
            }
            .padding(.trailing)

        }
        .padding(.bottom)
    }
    
    /*ScrollView {
        LazyVStack(alignment: .leading, spacing: 0) {
            /*HStack {
             Spacer()
             Button(action: {
             socketManager.loadMoreMessagesInCurrentBuffer()
             }, label: {
             Label("Load more messages", systemImage: "arrow.circlepath").padding()
             })
             Spacer()
             }*/
            ForEach(socketManager.channelsStore[socketManager.currentBuffer]?.messages ?? []) { msg in
                HStack(alignment: .top) {
                    Text(.init(String(msg.id))).onTapGesture {
                        proxy.scrollTo(socketManager.channelsStore[socketManager.currentBuffer]?.messages.last?.id)
                    }
                    
                    if showTimestampsSetting {
                        if let msgParsedDate = msg.timeParsed {
                            LoungeText(text: formatTimestamp(parsedDate: msgParsedDate))
                                .foregroundColor(.gray)
                        } else {
                            LoungeText(text: "Unknown TS")
                        }
                    }
                    
                    if let msgNick = msg.from {
                        LoungeText(text: truncateNickname(origNickname: msgNick.nick))
                            .foregroundColor(getNicknameColor(nickname: msgNick.nick))
                    } else {
                        LoungeText(text: "SYSTEM")
                    }
                    
                    Text(.init(msg.text)) // id here is important for the scroll proxy to work apparently
                        .padding(.horizontal)
                        .textSelection(.enabled)
                        .font(.system(.body, design: useMonospaceFont == true ? .monospaced : .default)) // TODO: make into custom Text element or sth
                        .environment(\.openURL, OpenURLAction { url in
                            handleUserClickedLink(url: url)
                            return .handled
                        })
                }
                .padding(
                    EdgeInsets(
                        top: 0,
                        leading: 0,
                        bottom: 0,
                        trailing: 0
                    )
                )
                .listRowInsets(EdgeInsets(top: 0,
                                          leading: 0,
                                          bottom: 0,
                                          trailing: 0
                                         ))
                .onTapGesture {
                    //scrollProxy?.scrollTo(socketManager.channelsStore[socketManager.currentBuffer]?.messages.last?.id, anchor: .bottom)
                }
                .refreshable {
                    socketManager.loadMoreMessagesInCurrentBuffer()
                }
                .id(msg.id)
                .contextMenu {
                    Button {
                        let pasteboard = UIPasteboard.general
                        if let msgParsedDate = msg.timeParsed {
                            let timestamp = formatTimestamp(parsedDate: msgParsedDate)
                            pasteboard.string = "\(timestamp) <\(msg.from?.nick ?? "SYSTEM")> \(msg.text)"
                        }
                    } label: {
                        Label("Copy to clipboard with timestamp", systemImage: "doc.on.doc.fill")
                        
                    }
                    Button {
                        let pasteboard = UIPasteboard.general
                        pasteboard.string = "<\(msg.from?.nick ?? "SYSTEM")> \(msg.text)"
                    } label: {
                        Label("Copy to clipboard without timestamp", systemImage: "doc.on.doc")
                    }
                }
            }.listStyle(.plain)
                .listRowSpacing(1.0)
                .listSectionSpacing(2.0)
                .listRowSeparator(.hidden)
                .scrollDismissesKeyboard(.never)
            // TODO: Auto-scroll needs some love and care
                .onAppear {
                    scrollProxy = proxy
                }
                .onChange(of: socketManager.channelsStore[socketManager.currentBuffer]?.messages.last) { oldValue, newValue in
                    
                    print("\n [BEFORE MESSAGE] scrolledID is = \(String(describing: scrolledID)), \n the last messgae is = \(String(describing: socketManager.channelsStore[socketManager.currentBuffer]?.messages.last?.id))")
                    if let oldMessageId = oldValue?.id {
                        scrollProxy?.scrollTo(socketManager.channelsStore[socketManager.currentBuffer]?.messages.last?.id, anchor: .bottom)
                        
                        // We are scrolled all the way down to the (OLD)last message, let's scroll since we new have a new one to scroll even further down to.
                        if oldMessageId == scrolledID {
                            // Set the scrolledID variable, since we are forcing a scroll with scrollTo()
                            // scrolledID = socketManager.channelsStore[socketManager.currentBuffer]?.messages.last?.id
                            
                            withAnimation {
                                scrollProxy?.scrollTo(socketManager.channelsStore[socketManager.currentBuffer]?.messages.last?.id, anchor: .bottom)
                            }
                        } else {
                            print("I am not scrolling for you, you are probably reading the backlog. TODO: here we could show some sort of highlight of new activity in the UI or sth")
                        }
                    }
                    
                    print("\n [AFTER MESSAGE] scrolledID is = \(String(describing: scrolledID)), \n the last messgae is = \(String(describing: socketManager.channelsStore[socketManager.currentBuffer]?.messages.last?.id))")
                }
                .onChange(of: socketManager.currentBuffer) {
                    withAnimation {
                        scrollProxy?.scrollTo(socketManager.channelsStore[socketManager.currentBuffer]?.messages.last?.id, anchor: .bottomTrailing)
                    }
                }
        }
    }
    .scrollPosition(id: $scrolledID, anchor: .bottomLeading)*/
    /*.onChange(of: scrolledID) { oldValue, newValue in
        //print(newValue ?? "No value set")
    }*/
    //.frame(maxWidth: .infinity, maxHeight: .infinity)
    //.ignoresSafeArea(.keyboard)
    ///*.scrollTargetLayout()
        //.scrollDismissesKeyboard(.automatic)
        /*.toolbar {
            ToolbarItem(placement: .keyboard) {

            }
        }*/
    
    /**ForEach(socketManager.channelsStore[socketManager.currentBuffer]?.messages ?? []) { msg in
     HStack(alignment: .top) {
         Text(.init(String(msg.id))).onTapGesture {
             proxy.scrollTo(socketManager.channelsStore[socketManager.currentBuffer]?.messages.last?.id)
         }
         
         if showTimestampsSetting {
             if let msgParsedDate = msg.timeParsed {
                 LoungeText(text: formatTimestamp(parsedDate: msgParsedDate))
                     .foregroundColor(.gray)
             } else {
                 LoungeText(text: "Unknown TS")
             }
         }
         
         if let msgNick = msg.from {
             LoungeText(text: truncateNickname(origNickname: msgNick.nick))
                 .foregroundColor(getNicknameColor(nickname: msgNick.nick))
         } else {
             LoungeText(text: "SYSTEM")
         }
         
         Text(.init(msg.text)) // id here is important for the scroll proxy to work apparently
             .padding(.horizontal)
             .textSelection(.enabled)
             .font(.system(.body, design: useMonospaceFont == true ? .monospaced : .default)) // TODO: make into custom Text element or sth
             .environment(\.openURL, OpenURLAction { url in
                 handleUserClickedLink(url: url)
                 return .handled
             })
     }*/
    @State var dataID: Int?
    var messageView: some View {
    
        ScrollViewReader { proxy in
            ScrollView {
                VStack {
                    // VStack {
                    LazyVStack {
                        ForEach(socketManager.channelsStore[socketManager.currentBuffer]?.messages ?? []) { msg in
                            HStack(alignment: .top) {
                                /*Color.red
                                 .frame(height: 100)
                                 .overlay {*/
                                
                                /*Text(.init(String(msg.id))).onTapGesture {
                                    print("BEFORE: \(String(describing: dataID))")
                                    proxy.scrollTo(socketManager.channelsStore[socketManager.currentBuffer]?.messages.last?.id, anchor: .bottomTrailing)
                                    dataID = socketManager.channelsStore[socketManager.currentBuffer]?.messages.last?.id
                                    print("AFTER: \(String(describing: dataID))")
                                } .multilineTextAlignment(.leading)
                                Spacer()
                                */
                                
                                /*if showTimestampsSetting {
                                    if let msgParsedDate = msg.timeParsed {
                                        LoungeText(text: formatTimestamp(parsedDate: msgParsedDate))
                                            .foregroundColor(.gray)
                                    } else {
                                        LoungeText(text: "Unknown TS")
                                    }
                                }*/
                                Text(.init(String(msg.id)))
                                
                                if let msgNick = msg.from {
                                    LoungeText(text: truncateNickname(origNickname: msgNick.nick))
                                        .foregroundColor(getNicknameColor(nickname: msgNick.nick))
                                } else {
                                    LoungeText(text: "SYSTEM")
                                }
                                Text(.init(msg.text)) // id here is important for the scroll proxy to work apparently
                                    .padding(.horizontal)
                                    .textSelection(.enabled)
                                    .font(.system(.body, design: useMonospaceFont == true ? .monospaced : .default)) // TODO: make into custom Text element or sth
                                    .environment(\.openURL, OpenURLAction { url in
                                        handleUserClickedLink(url: url)
                                        return .handled
                                    }).multilineTextAlignment(.leading)
                                    //.padding()
                                    //.background()
                                Spacer()
                            }.id(msg.id) // end of HStack
                                .contextMenu {
                                    Button {
                                        let pasteboard = UIPasteboard.general
                                        if let msgParsedDate = msg.timeParsed {
                                            let timestamp = formatTimestamp(parsedDate: msgParsedDate)
                                            pasteboard.string = "\(timestamp) <\(msg.from?.nick ?? "SYSTEM")> \(msg.text)"
                                        }
                                    } label: {
                                        Label("Copy to clipboard with timestamp", systemImage: "doc.on.doc.fill")
                                        
                                    }
                                    Button {
                                        let pasteboard = UIPasteboard.general
                                        pasteboard.string = "<\(msg.from?.nick ?? "SYSTEM")> \(msg.text)"
                                    } label: {
                                        Label("Copy to clipboard without timestamp", systemImage: "doc.on.doc")
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                //}
                        } // ForEach END
                        .frame(maxWidth: .infinity)
                        .onChange(of: socketManager.channelsStore[socketManager.currentBuffer]?.messages.last?.id) { oldValue, newValue in
                            if oldValue == dataID {
                                proxy.scrollTo(socketManager.channelsStore[socketManager.currentBuffer]?.messages.last?.id, anchor: .bottomTrailing)
                                dataID = newValue
                            } else {
                                if dataID == nil {
                                    dataID = newValue
                                }
                            }
                        
                           print("oldValue = ", oldValue, "newValue = ", newValue, "dataID = ", dataID)
                        }
                        
                    }.scrollTargetLayout() // LazVStack END
                       
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollPosition(id: $dataID, anchor: .bottomLeading)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    
    var dataIDText: String {
        dataID.map(String.init(describing:)) ?? "None"
    }
    var body: some View {
        ZStack {
            NavigationStack {
                VStack {
                    messageView
                    bottomField
                    Text("\(dataIDText)")
                    
                }
                .navigationBarItems(
                    leading: Button(action: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                isBufferViewVisible.toggle()
                            }
                        }
                    }) {
                        Image(systemName: "menucard") // sidebar.left
                    },
                    
                    trailing: Button(action: {
                        isSettingsVisible.toggle()
                    }) {
                        Image(systemName: "gear")
                    }
                )

                // TODO: Remove this sheet stuff?
                // TODO: Probably make the settings sheet not be a sheet?
                // TODO: ^ Dunno navigation instead? We shall see about it.
                .sheet(isPresented: $isPreviewViewVisible){
                    PreviewView(isPreviewViewVisible: $isPreviewViewVisible, imageURL: $currentPreviewURL, isVideo: $currentPreviewIsVideo)
                }
                .sheet(isPresented: $isTestViewVisible) {
                    TestView(isTestViewVisible: $isTestViewVisible)
                }
                .sheet(isPresented: $isSettingsVisible) {
                    SettingsView(isSettingsVisible: $isSettingsVisible).onDisappear() {
                        // TODO: When we close settings we scroll down, because the keyboard might screw up the scroll position, lol :|
                        //scrollProxy?.scrollTo(socketManager.messages.last, anchor: .bottom)
                    }
                }.navigationTitle(socketManager.channelsStore[socketManager.currentBuffer]?.chanName ?? "iLounge")
            }

            BufferView(isBufferViewVisible: $isBufferViewVisible, socketManager: socketManager)
        }
    }
    
    func handleUserClickedLink(url: URL) {
        if isImage(text: url.absoluteString) {
            currentPreviewURL = url.absoluteString
            currentPreviewIsVideo = false
            isPreviewViewVisible.toggle()
        } else if isVideo(text: url.absoluteString) {
            currentPreviewURL = url.absoluteString
            currentPreviewIsVideo = true
            isPreviewViewVisible.toggle()
        }
        else {
            UIApplication.shared.open(url)
        }
    }
    
    func sendMessage() {
        if !messageInput.isEmpty {
            socketManager.sendMessage(message: messageInput, channel_id: 2)
            messageInput = ""
            //scrollProxy?.scrollTo(socketManager.messages.count - 1, anchor: .bottom)
        }
        else
        {
            print("isTestViewVisible = \(isTestViewVisible)")
            isTestViewVisible.toggle()
        }
    }
}


struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}


#Preview {
    ContentView()
}
