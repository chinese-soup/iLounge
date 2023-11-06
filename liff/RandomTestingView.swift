//
//  RandomTestingView.swift
//  liff
//
//  Created by Jakub Mach on 06.11.2023.
//

import Foundation
import SwiftUI
import CoreData

struct TestView: View {
    @Binding var isTestViewVisible: Bool
    private let width = UIScreen.main.bounds.width - 100
    let baseText = "apple pear orange lemon"
    let baseUrl = "https://github.com/search/repositories?q="
    
    var body: some View {
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
