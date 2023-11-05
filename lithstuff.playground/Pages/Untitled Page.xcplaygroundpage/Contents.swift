import UIKit

var greeting = "Hello, playground"


class WebSocketManager: ObservableObject {
    @Published var messages: [String] = []
    var socket: WebSocket?
    var password: String?

    init(password: String? = nil) {
        self.password = password
        setupWebSocket()
    }

    func setupWebSocket() {
        let urlString = "wss://shitpost.fun:443/weechat"
        if let url = URL(string: urlString) {
            socket = WebSocket(request: URLRequest(url: url))
            socket?.delegate = self
            socket?.connect()
        }
    }
    
    func sendInit() {
        print("Hi i am sending init")
           if let password = password {
               print("password is \(password)")
               let initCommand = "init password=\(password)\n"
               socket?.write(string: initCommand)
               let versionCommand = "info version\n"
               socket?.write(string: versionCommand)
           }
       }

    func sendMessage(_ message: String) {
        socket?.write(string: message)
    }
}

extension Data {
    var int8: Int8 { withUnsafeBytes({ $0.load(as: Int8.self) }) }
    var int32: Int32 { withUnsafeBytes({ $0.load(as: Int32.self) }) }
    var float32: Float32 { withUnsafeBytes({ $0.load(as: Float32.self) }) }
}

extension WebSocketManager: WebSocketDelegate {
    
    func parseData(data: Data) {
        parseHeader(data: data)
    }
    
    
    func parseHeader(data: Data) {
        // Your binary data
        print(data)
        
        var dataPointer = UnsafeRawPointer(data.withUnsafeBytes { $0.baseAddress })
       
        let messageLength = Int32(bigEndian: Int32(dataPointer!.load(as: Int32.self)))
        dataPointer = dataPointer?.advanced(by: 4)
        
        
        let compressionByte = UInt8(bigEndian: UInt8(dataPointer!.load(as: UInt8.self)))
        dataPointer = dataPointer?.advanced(by: 1)
        
        //let idBytes = Int32(bigEndian: Int32(dataPointer!.load(as: Int32.self)))
        dataPointer = dataPointer?.advanced(by: 4)

        let infString = String(data: Data(bytes: dataPointer!, count: 3), encoding: .utf8)
        dataPointer = dataPointer?.advanced(by: 3)
        var parsedStrings: [String] = []
        
        let stringLength = Int32(bigEndian: dataPointer!.load(as: Int32.self))
        print("dataPointer before = \(dataPointer)")
        dataPointer = dataPointer!.advanced(by: 4)
        
        if stringLength > 0 {
            let stringData = Data(bytes: dataPointer!, count: Int(stringLength))
            if let string = String(data: stringData, encoding: .utf8) {
                parsedStrings.append(string)
                print("String legnth = ", stringData.count)
                print("String", string)
                dataPointer = dataPointer!.advanced(by: stringData.count)
            } else {
                print("Failed to decode a string")
            }
        } else {
            print("Invalid string length or insufficient data.")
        }
        /*// Parse the length of the whole message (big-endian integer)
        let messageLength = data[0...3].int32.bigEndian

        // Parse the compression byte (1 char)
        let compressionByte = data[4...4].int8
        
        // Parse the compression byte (1 char)
        let id = data[5...8]
        
        let inf_string = data[8...11]
        
        print(inf_string)*/
    }
    
    func parse() {
        // stub
    }
    
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocketClient) {
        print("Received data --- didReceive")
        
        switch event {
        case .connected(let headers):
            print("websocket is connected: \(headers)")
            sendInit()
        case .disconnected(let reason, let code):
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            print("Received text: \(string)")
        case .binary(let data):
            print("Received data: \(data.count)")
            parseData(data: data)
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            print("cancelled")
        case .error(let error):
            print("bla")
            break
        case .peerClosed:
            print("peerClosed")
        }
    }
}
