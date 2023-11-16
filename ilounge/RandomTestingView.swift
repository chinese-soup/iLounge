//
//  RandomTestingView.swift
//  ilounge
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



    @State private var offset = CGFloat.zero


    @State private var idcko: Int?
    var body: some View {

        ScrollView {
            VStack {
                ForEach(0..<100, id: \.self) { i in
                    Text("Item \(i)").padding()
                }
            }.background(GeometryReader {
                Color.clear.preference(key: ViewOffsetKey.self,
                    value: -$0.frame(in: .named("scroll")).origin.y)
            })
            /*.onPreferenceChange(ViewOffsetKey.self) {
                //print("\($0)")
                //print("offset >> \($0)")
            }*/
        }.coordinateSpace(name: "scroll")
        .onChange(of: idcko) { oldValue, newValue in
            print(newValue ?? "No value set")
        }
        .scrollPosition(id: $idcko)
    }

        /*List(self.availableFonts(), id: \.self) { fontName in
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
        .frame(width: self.width)*/
    }

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}
