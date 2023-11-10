//
//  ContentView.swift
//  liff
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

    // Visibility
    @State private var isSettingsVisible = false
    @State private var isTestViewVisible = false
    @State private var isPreviewViewVisible = false
    @State private var isBufferViewVisible = false
    @FocusState private var textFieldIsFocused: Bool

    @State public var scrollProxy: ScrollViewProxy? = nil
    @State private var selectedEntry: String? = nil

    @State private var currentPreviewURL = "https://picsum.photos/600" // TODO: Remove

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
    
    // View's constructor
    init() {
        print("Hello from init()")
        self.socketManager = SocketManagerWrapper()
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

    var body: some View {
        ZStack {
            NavigationStack {
                VStack {
                    ScrollView {
                        ScrollViewReader { proxy in
                            VStack(alignment: .leading, spacing: 5) {
                                //ForEach(Array(socketManager.channelsStore.keys), id: \.self) { key in
                                ForEach(socketManager.channelsStore[socketManager.currentBuffer]?.messages ?? [], id: \.self.id) { msg in
                                    //Text("\(key): \(socketManager.channelsStore[key]?.chanName ?? "asdf")")
                                    HStack {
                                        if showTimestampsSetting {
                                            if let msgParsedDate = msg.timeParsed {
                                                Text(formatTimestamp(parsedDate: msgParsedDate))
                                                    .font(.system(.body, design: useMonospaceFont == true ? .monospaced : .default)) // TODO: make into custom Text element or sth
                                                    .foregroundColor(.gray)

                                            } else {
                                                Text("Unknown TS")
                                                    .font(.system(.body, design: useMonospaceFont == true ? .monospaced : .default)) // TODO: make into custom Text element or sth
                                            }
                                        }

                                        if let msgNick = msg.from {
                                            //Text(msgNick.nick.count > nickLengthSetting ? String(msgNick.nick.prefix(nickLengthSetting)) : msgNick.nick)
                                            Text(truncateNickname(origNickname: msgNick.nick))
                                                .font(.system(.body, design: useMonospaceFont == true ? .monospaced : .default)) // TODO: make into custom Text element or sth
                                        } else {
                                            Text("SYSTEM")
                                                .font(.system(.body, design: useMonospaceFont == true ? .monospaced : .default)) // TODO: make into custom Text element or sth
                                        }

                                        Text(.init(msg.text)).id(msg.id) // id here is important for the scroll proxy to wok apparently
                                            .padding(.horizontal)
                                            .font(.system(.body, design: useMonospaceFont == true ? .monospaced : .default))
                                            //.textSelection(.enabled)
                                            .environment(\.openURL, OpenURLAction { url in
                                                handleUserClickedLink(url: url)
                                                return .handled
                                            })
                                        /*.onTapGesture {
                                         selectedEntry = msg
                                         let pasteboard = UIPasteboard.general
                                         pasteboard.string = msg
                                         }*/
                                    }
                                    .contextMenu {
                                        Button {
                                        } label: {
                                            Label("Copy to clipboard with timestamp", systemImage: "doc.on.doc.fill")

                                        }
                                        Button {
                                            let pasteboard = UIPasteboard.general
                                            pasteboard.string = "\(msg.from) \(msg.text)" // TODO: lol
                                        } label: {
                                            Label("Copy to clipboard without timestamp", systemImage: "doc.on.doc")
                                        }
                                    }
                                }
                            }
                            .onAppear {
                                scrollProxy = proxy
                            }
                            // TODO: Auto-scroll needs some love and care
                            .onChange(of: socketManager.channelsStore[socketManager.currentBuffer]?.messages) {
                                withAnimation {
                                    scrollProxy?.scrollTo(socketManager.channelsStore[socketManager.currentBuffer]?.messages.last?.id, anchor: .bottom)
                                }
                            }
                            .onChange(of: socketManager.currentBuffer) {
                                withAnimation {
                                    scrollProxy?.scrollTo(socketManager.channelsStore[socketManager.currentBuffer]?.messages.last?.id, anchor: .bottom)
                                }
                            }
                        }
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)


                    bottomField
                }
                .navigationBarItems(
                    leading: Button(action: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            isBufferViewVisible.toggle()
                            print("isBufferViewVisible = ", isBufferViewVisible)
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
                }.navigationTitle(socketManager.channelsStore[socketManager.currentBuffer]?.chanName ?? "iLounge")
            }.scrollDismissesKeyboard(.interactively)

            //.scrollDismissesKeyboard(.interactively)
            BufferView(isBufferViewVisible: $isBufferViewVisible, socketManager: socketManager)
        }
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


#Preview {
    ContentView()
}
