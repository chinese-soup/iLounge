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
    @State private var isSettingsVisible = false
    @State private var isTestViewVisible = false
    @State private var isPreviewViewVisible = false
    @State public var scrollProxy: ScrollViewProxy? = nil
    @State private var selectedEntry: String? = nil
    
    @State private var currentPreviewURL = "https://picsum.photos/600" // TODO: Remove
    
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
        self.socketManager = SocketManagerWrapper()
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
                                        /*.onTapGesture {
                                            selectedEntry = msg
                                            let pasteboard = UIPasteboard.general
                                            pasteboard.string = msg
                                           
                                        }*/
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
                    }.frame(maxWidth: .infinity, maxHeight: .infinity).scrollDismissesKeyboard(.interactively)
                    
                    HStack {
                        TextField("Type a message", text: $messageInput) // TextEditor for multiline, but then I can't send lol
                            .onSubmit {
                                DispatchQueue.main.async {
                                    sendMessage()
                                }
                            }
                            .frame(maxHeight: 40)
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
        textFieldIsFocused = true
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
