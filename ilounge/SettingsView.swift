//
//  SettingsView.swift
//  ilounge
//
//  Created by Jakub Mach on 06.11.2023.
//

import SwiftUI


struct SettingsView: View {
    // Bindings
    @Binding var isSettingsVisible: Bool
    
    // Connection settings
    @AppStorage("loungeUsername") private var usernameSetting: String = ""
    @AppStorage("loungePaassword") private var passwordSetting: String = ""
    @AppStorage("loungeHostname") private var hostnameSetting: String = ""
    @AppStorage("loungePort") private var portSetting: String = "8080" // TODO: This is a String because Integer hated me, look into it again
    @AppStorage("loungeUseSsl") private var useSslSetting: Bool = false


    // Display settings
    @AppStorage("loungeShowTimestamps") private var showTimestampsSetting: Bool = true
    @AppStorage("loungeTimestampFormat") private var timestampFormatSetting: String = "HH:mm:ss"

    @AppStorage("loungeUseMonospaceFont") private var useMonospaceFont: Bool = false
    @AppStorage("loungeShowJoinPart") private var showJoinPartSetting: Bool = true

    @AppStorage("loungeNickLength") private var nickLengthSetting: Int = 0

    // Advanced settings TODO: Get rid of WS/Polling, automagically do this
    @AppStorage("loungeForceWS") private var forceWebsocketsSetting: Bool = false
    @AppStorage("loungeForcePoll") private var forcePollingSetting: Bool = false

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
                    HStack {
                        Text("Username")
                        Spacer()
                        TextField("Username", text: $usernameSetting)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Password")
                        Spacer()
                        SecureField("Password", text: $passwordSetting)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Section(header: Text("Display Settings")) {
                    HStack {
                        Text("Show timestamps")
                        Spacer()
                        Toggle("", isOn: $showTimestampsSetting)
                    }
                    HStack {
                        Text("Timestamp format")
                        Spacer()
                        TextField("HH:mm:ss", text: $timestampFormatSetting)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Use monospace font")
                        Spacer()
                        Toggle("", isOn: $useMonospaceFont)
                    }
                    HStack {
                        Text("Show join/part")
                        Spacer()
                        Toggle("", isOn: $showJoinPartSetting) // TODO: FIXME actual binding
                    }
                    HStack {
                        Text("Align nicknames")
                        Spacer()
                        Stepper("\(nickLengthSetting == 0 ? "(disabled)" : "to \(nickLengthSetting) characters")", value: $nickLengthSetting, in: 0...15)
                    }
                }
                Section(header: Text("Advanced Settings")) {
                    HStack {
                        Text("Force websockets")
                        Spacer()
                        Toggle("", isOn: $forceWebsocketsSetting)
                    }
                    HStack {
                        Text("Force polling")
                        Spacer()
                        Toggle("", isOn: $forcePollingSetting)
                    }
                }
            }.listStyle(GroupedListStyle())
            .navigationBarTitle("Settings")
            .navigationBarItems(trailing: Button(action: {
                isSettingsVisible.toggle()
                saveSettings()
            }) {
                Text("Save")
            })
        }
    }
    
    func saveSettings() {
        print("Settings saved")
        UserDefaults.standard.set(hostnameSetting, forKey: "loungeHostname")
        UserDefaults.standard.set(portSetting, forKey: "loungePort")
        UserDefaults.standard.set(useSslSetting, forKey: "loungeUseSsl")
        
        UserDefaults.standard.set(showTimestampsSetting, forKey: "loungeShowTimestamps")
        UserDefaults.standard.set(useMonospaceFont, forKey: "loungeUseMonospaceFont")
        UserDefaults.standard.set(showJoinPartSetting, forKey: "loungeShowJoinPart")
    }
    
}


/*
#Preview {
    @State var isSettingsVisible = true
    SettingsView(isSettingsVisible: $isSettingsVisible)
}
*/
