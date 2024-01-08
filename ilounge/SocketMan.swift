//
//  SocketMan.swift
//  liff
//
//  Created by Jakub Mach on 06.11.2023.
//

import Foundation
import SwiftUI
import Starscream
import SocketIO
import CoreData


class SocketManagerWrapper: ObservableObject {
    @Published var currentBuffer: Int = 0
    
    @Published var channelsStore: [Int: Channel] = [:]
    // TODO: OR well, make everything into models, really :--)
    // TODO: E.g. buffers (servers / channels)
    // TODO: E.g. NickList etc.
    //
    var socket: SocketManager?
    @AppStorage("loungeUsername") private var usernameSetting: String = ""
    @AppStorage("loungePaassword") private var passwordSetting: String = ""
    @AppStorage("loungeHostname") private var hostnameSetting: String = "localhost"
    @AppStorage("loungePort") private var portSetting: String = "8080"
    @AppStorage("loungeUseSsl") private var useSslSetting: Bool = false
    
    // Advanced settings TODO: Get rid of WS/Polling, automagically do this
    @AppStorage("loungeForceWS") private var forceWebsocketsSetting: Bool = false
    @AppStorage("loungeForcePoll") private var forcePollingSetting: Bool = false

    init() {
        var proto = "ws"
        if useSslSetting {
            proto = "wss"
            proto = "https"
        }
        if let formattedSocketURL = URL(string:"\(proto)://\(hostnameSetting):\(portSetting)/") {
            print("URL is \(formattedSocketURL)")
            socket = SocketManager(socketURL: formattedSocketURL, config: [.log(false), .forceWebsockets(forceWebsocketsSetting), .forcePolling(forcePollingSetting)])
            DispatchQueue.main.async { [self] in
                configureSocket()
            }
        }
        else {
            print("SOCKET FAILED because WRONG HOSTNAME") // TODO: uhh
        }
    }
    
    func sendMessage(message: String, channel_id: Int = 2) {
        // TODO: Un-hardcode target, load from the buffer model that we want to send to the "current buffer"
        let msgToSend = ["target": currentBuffer, "text": message] as [String : Any]
        socket?.defaultSocket.emit("input", msgToSend)
    }

    func loadMoreMessagesInCurrentBuffer() {
        let lastMessageId = channelsStore[currentBuffer]?.messages.first?.id as? Int
        //.sorted(by: { $0.id < $1.id })
        print("[LoadMoreMessagesInCurrentBuffer]  LASt mesasged id = \(String(describing: lastMessageId))")
        if lastMessageId == 0 { // TODO: This is probably a cause for 1) Start the app 2) Open buffer 3) Open buffer again -> old messsages are pretending to be new messages at the bottom (of course not counting the fact we append them at the bottom instead of sorting by time / id )

            print("[LoadMoreMessagesInCurrentBuffer]  Oh no, lastmsgid == 0")
        } else {
            print("[LoadMoreMessagesInCurrentBuffer] lastMessageId sending = \(String(describing: lastMessageId))")
            let moreMessagesRequest = ["target": currentBuffer, "lastId": lastMessageId ?? 0, "condensed": true] as [String : Any]
            socket?.defaultSocket.emit("more", moreMessagesRequest)
        }
    }

    func openBuffer(channel_id: Int) {
        socket?.defaultSocket.emit("open", channel_id)

        // TODO: !!! This has the side-effect of the first message that appears from "init" (the thing we get before we even send "more")
        // TODO: to be on the top of the history,
        // TODO: even though it should be the latest message
        // TODO: So far fixed by sorting the array every append using the IDs, maybe I'll keep it that way tbh it fixes a lot of issues for "free".

        // TODO: This currently DUPLICATES MESSAGES UPON CHANGING TO THE BUFFER (last X mesagess repeat)

        let lastMessageId = channelsStore[channel_id]?.messages.last?.id as? Int
        print("lastMessageId sending = \(String(describing: lastMessageId))") // TODO: ?

        let moreMessagesRequest = ["target": channel_id, "lastId": lastMessageId ?? 0, "condensed": true] as [String : Any]
        socket?.defaultSocket.emit("more", moreMessagesRequest)
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

    struct Channel: Hashable, Identifiable {
        let id: Int
        let chanId: Int
        let chanName: String
        let chanType: String
        let topic: String
        var messages: [Message] = [] {
            didSet {
                messages.sort(by: { $0.id < $1.id })
            }
        }
        let opened: Bool
    }

    struct Message: Hashable, Identifiable, Equatable {
        let id: Int
        let channelName: String
        let showInActive: Bool
        let error: String? // optional!
        let text: String
        let type: String
        let timeOrig: String
        let timeParsed: Optional<Date>
        let highlight: Bool
        let from: MessageFrom?
        // missing:
        // let self: Bool
        // let highlight: Int
        // let users: Array<?????> // users that the text highlighted

    }

    struct MessageFrom: Hashable {
        let mode: String
        let nick: String
    }

    func parseMessageData(message: Dictionary<String, Any>) -> Message? {
        let messageId = message["id"] as! Int

        // Text
        let messageText = message["text"] as! String
        //let messageTextWithMarkdown = self.replaceLinksWithMarkdownHyperlinks(origMsgText: messageText)

        // Timestamp
        let messageTsStr = message["time"] as! String
        // If we can parse the timestamp, change it to correct format
        let messageDateUTC = self.parseTimestamp(isoDate: messageTsStr)

        let messageType = message["type"] as! String

        // From
        var messageFromObj: MessageFrom?
        if let msgfrom = message["from"] as? Dictionary<String, Any>,
           let messageFromNick = msgfrom["nick"] as? String,
           let messageFromMode = msgfrom["mode"] as? String {
            messageFromObj = MessageFrom(mode: messageFromMode, nick: messageFromNick)
        }
        // Final message format
        // TODO: Proper model that is decodable!!!

        let newMessage = Message(id: messageId, channelName: "", showInActive: false, error: nil, text: messageText, type: messageType, timeOrig: messageTsStr, timeParsed: messageDateUTC ?? nil, highlight: false, from: messageFromObj)

        return newMessage
    }

    private func configureSocket() {
        
        // TODO: Use for debugging to get all the events handled
        //socket?.defaultSocket.onAny {print("Got event: \($0.event), with items: \($0.items)")}
        socket?.defaultSocket.on(clientEvent: .statusChange) { data, ack in
            print("Status change", data, ack)

        }
        
        socket?.defaultSocket.on(clientEvent: .connect) { data, ack in
            print("Socket connected", data, ack)
        }

        socket?.defaultSocket.on("more") { [self] data, ack in
            if let parsedData = data.first as? Dictionary<String,Any> {
                print("more", parsedData)
                if let channelId = parsedData["chan"] as? Int,
                   let totalMessages = parsedData["totalMessages"] as? Int {
                    print("total messages = \(totalMessages), chanid = \(channelId)")
                    if let messagesParsed = parsedData["messages"] as? Array<Dictionary<String, Any>> {
                        print("messages parsed= \(messagesParsed.count)")

                        for message in messagesParsed {
                            if let newMessageObj = parseMessageData(message: message) {
                                print("More, message = \(newMessageObj.id)")
                                if (self.channelsStore[channelId]?.messages.firstIndex(where: { $0.id == newMessageObj.id })) != nil {
                                    print("This message already exists bro.") // TODO: Get rid of or nah? Move to func maybe... we have IDs after all...
                                } else {
                                    print("Appending \(newMessageObj) .--- ")
                                    self.channelsStore[channelId]?.messages.append(newMessageObj)
                                }
                            }
                        }
                    }
                }
            }
        }

        socket?.defaultSocket.on("names") { data, ack in
            // TODO: names
        }

        socket?.defaultSocket.on("open") { data, ack in
            print("open")
            if let chanId = data.first as? Int {
                print("Got 'open' event with channelId = \(chanId), opening that buffer.")
                //self.openBuffer(channel_id: chanId)
            }

        }

        socket?.defaultSocket.on("msg") { data, ack in
            /* example msg
             msg =     {
                 channel = "#test.cz";
                 error = "chanop_privs_needed";
                 from =         {
                 };
                 id = 476;
                 previews =         (
                 );
                 reason = "You're not a channel operator";
                 self = 0;
                 showInActive = 0;
                 text = "";
                 time = "2023-11-06T21:14:56.430Z";
                 type = error;
             };
             */
            // Types:
            // type: error
            // type: message
            // type: quit
            // type:
            
            /*if let message = data.first as? Dictionary<String,Any>,
               let msg = message["msg"] as? Dictionary<String,Any> {
                // TODO: ID - good for the model I wanna make later, I guess :-)
                let messageId = message["id"] as? Int
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
                   let messageNick = messageFrom["nick"] as? String { // TODO: i'm gonna fix these when i make proper models
                    messageFinal = "\(messageTs) <\(messageNick)> \(messageTextWithMarkdown)"
                }
                else {
                    messageFinal = "\(messageTs) <SYSTEM> \(messageTextWithMarkdown)" // TODO: This is wrong
                }
                
                // Final message format
                // TODO: Proper models
                self.messages.append(messageFinal)*/
            if let message = data.first as? Dictionary<String,Any>,
               let msg = message["msg"] as? Dictionary<String,Any>,
               let channelId = message["chan"] as? Int {

                if let newMessageObj = self.parseMessageData(message: msg) {
                    print("Appending \(newMessageObj) .--- ")
                    self.channelsStore[channelId]?.messages.append(newMessageObj)
                }
            }
        }
        
        socket?.defaultSocket.on("message") { data, ack in
            print("message \(data)")
            if let message = data.first as? String {
                print(message)
            }
        }
        
        socket?.defaultSocket.on("connect") { data, ack in
            print("connect \(data)")
            if let message = data.first as? String {
                print("connect event: \(String(describing: message))")
            }
        }
        
        socket?.defaultSocket.on("init") {data, ack in
            if let message = data.first as? Dictionary<String,Any>,
               let networks = message["networks"] as? Array<Dictionary<String,Any>> {
                for network in networks {
                    if let channels = network["channels"] as? Array<Dictionary<String, Any>> {
                        for channel in channels {
                            // TODO: I should be able to deode this into `DeCodable` instead ... look into this (struct Channel)
                            if let chanId = channel["id"] as? Int,
                               let chanName = channel["name"] as? String,
                               let chanTopic = channel["topic"] as? String,
                               let chanType = channel["type"] as? String {

                                let newChan = Channel(id: chanId, chanId: chanId, chanName: chanName, chanType: chanType, topic: chanTopic, messages: [], opened: false)
                                self.channelsStore[newChan.chanId] = newChan

                                if let messagesParsed = channel["messages"] as? Array<Dictionary<String, Any>> {
                                    for message in messagesParsed {
                                        if let newMessageObj = self.parseMessageData(message: message) {
                                            print("More, message = \(newMessageObj.id)")
                                            if (self.channelsStore[newChan.chanId]?.messages.firstIndex(where: { $0.id == newMessageObj.id })) != nil {
                                                print("This message already exists bro.") // TODO: Get rid of or nah? Move to func maybe... we have IDs after all...
                                            } else {
                                                print("Appending \(newMessageObj) .--- ")
                                                self.channelsStore[newChan.chanId]?.messages.append(newMessageObj)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                if let active = message["active"] as? Int {
                    print("Setting active buffer to \(active)")  // TODO: ADD A CHECK IF THE BUFFER EXISTS OR NOT
                    self.currentBuffer = active // TODO: Move to openBuffer() func?
                    self.openBuffer(channel_id: active)
                }
            }
        }
            
        socket?.defaultSocket.on("auth:start") { [self] data, ack in
            // we got  auth start's exgon gonan give it to em
            print("AUTH START BRo message \(String(describing:data))")
            let swiftDict: [String: String] = ["user": usernameSetting, "password": passwordSetting]

            socket?.defaultSocket.emit("auth:perform", swiftDict)
            
            if let message = data.first as? String {
                print("auth:start \(message)")
            }
        }
        
        socket?.defaultSocket.connect()
        
    }
}
