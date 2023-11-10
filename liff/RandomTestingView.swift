//
//  RandomTestingView.swift
//  liff
//
//  Created by Jakub Mach on 06.11.2023.
//

import Foundation
import SwiftUI
import CoreData
import CoreText

struct TestView: View {
    @Binding var isTestViewVisible: Bool
    //private let width = UIScreen.main.bounds.width - 100
    private let width = 500.0
    let baseText = "apple pear orange lemon"
    let baseUrl = "https://github.com/search/repositories?q="

    func availableFonts() -> [String] {
            var fonts: [String] = []

            for family in UIFont.familyNames {
                for name in UIFont.fontNames(forFamilyName: family) {
                    fonts.append(name)
                }
            }
        print("fonts count \(fonts.count)")

            return fonts
        }


    var body: some View {
        List(self.availableFonts(), id: \.self) { fontName in
                   Text(fontName)
                .padding(.leading)
                //.font(.custom(fontName, size: 16))
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
