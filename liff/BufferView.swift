//
//  BufferView.swift
//  liff
//
//  Created by Jakub Mach on 07.11.2023.
//

import SwiftUI

struct BufferView: View {
    @Binding var isBufferViewVisible: Bool
    @ObservedObject var socketManager: SocketManagerWrapper
    var sideBarWidth = UIScreen.main.bounds.size.width * 0.7
    var bgColor: Color = Color(.systemBackground.withAlphaComponent(0.9))

    var body: some View {
        if isBufferViewVisible {
            ZStack {
                GeometryReader { _ in
                    EmptyView()
                }.animation(.easeInOut.delay(0.5), value: isBufferViewVisible)

                .background(Color.black.opacity(0.8))
                .opacity(isBufferViewVisible ? 0.7 : 0)
                .onTapGesture {
                    isBufferViewVisible.toggle()
                }
                content
            }
            //.edgesIgnoringSafeArea(.all)
        }
    }

    var content: some View {
        HStack(alignment: .top) {
            ZStack(alignment: .top) {
                bgColor.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 40) {
                    ForEach(Array(socketManager.channelsStore.keys.sorted()), id: \.self) { key in
                        Button {
                            print("Switchin to \(key)")
                            isBufferViewVisible.toggle()
                            socketManager.openBuffer(channel_id: key)
                            socketManager.currentBuffer = key // TODO: Move to openBuffer() func?

                        } label: {
                            Label("\(key) \(socketManager.channelsStore[key]?.chanName ?? "<Unknown channel>")", systemImage: "bubble.left.and.bubble.right")
                                .bold()
                                .font(.headline)
                        }
                    }
                }.padding(0)
            }
            .frame(width: sideBarWidth)
            .offset(x: isBufferViewVisible ? 0 : -sideBarWidth)
            .animation(.easeInOut.delay(3.5), value: isBufferViewVisible)


            Spacer()
        }
    }
}
/*
#Preview {
    @State var isBufferViewVisible: Bool = true
    
    BufferView(isBufferViewVisible: $isBufferViewVisible)
}*/
