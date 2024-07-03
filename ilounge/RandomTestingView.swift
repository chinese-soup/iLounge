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
    @State var data: [String] = (0 ..< 25).map { String($0) }
    @State var dataID: String?
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Header")
                
                LazyVStack {
                    ForEach(data, id: \.self) { item in
                        Color.red
                            .frame(width: 100, height: 100)
                            .overlay {
                                Text("\(item)")
                                    .padding()
                                    .background()
                            }
                    }
                }
                .scrollTargetLayout()
            }
        }
        .scrollPosition(id: $dataID, anchor: .bottomLeading)
        .safeAreaInset(edge: .bottom) {
            Text("\(Text("Scrolled").bold()) \(dataIDText)")
            Spacer()
            Button {
                dataID = data.first
            } label: {
                Label("Top", systemImage: "arrow.up")
            }
            Button {
                dataID = data.last
            } label: {
                Label("Bottom", systemImage: "arrow.down")
            }
            Menu {
                Button("Prepend") {
                    let next = String(data.count)
                    data.insert(next, at: 0)
                }
                Button("Append") {
                    let next = String(data.count)
                    data.append(next)
                }
                Button("Remove First") {
                    data.removeFirst()
                }
                Button("Remove Last") {
                    data.removeLast()
                }
            } label: {
                Label("More", systemImage: "ellipsis.circle")
            }
        }
    }
    
    var dataIDText: String {
        dataID.map(String.init(describing:)) ?? "None"
    }
}
   // var body: some View {

        /*ScrollView {
         LazyVStack {
         ForEach(0..<100, id: \.self) { i in
         Text("Item \(i)").padding()
         }
         Color.clear
         .frame(width: 0, height: 0, alignment: .bottom)
         .onAppear {
         scrollAtBottom = true
         print("Scroll at bottom = true")
         }
         .onDisappear {
         scrollAtBottom = false
         print("Scroll at bottom = false")
         }
         }
         }*/
        /*.onPreferenceChange(ViewOffsetKey.self) {
         //print("\($0)")
         //print("offset >> \($0)")
         }*/
        
        

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


struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}
