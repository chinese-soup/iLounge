//
//  PreviewView.swift
//  liff
//
//  Created by Jakub Mach on 06.11.2023.
//

import SwiftUI

struct PreviewView: View {
    @Binding var isPreviewViewVisible: Bool
    @Binding var imageURL: String
    
    @State private var scale: Double = 1.0
    @State private var lastScale: Double = 1.0
    
    var body: some View {
        AsyncImage(
          url: URL(
            string: imageURL
            )) { image in
                image
          .resizable()
          .scaledToFill()
          .scaleEffect(scale)
          .frame(height: 240)
          .gesture(MagnificationGesture().onChanged { val in
                  let delta = val / self.lastScale
                  self.lastScale = val
                  let newScale = self.scale * delta
                  self.scale = newScale
              }.onEnded { _ in
                  self.lastScale = 1.0
              })
          } placeholder: {
              ZStack {
                  RoundedRectangle(cornerRadius: 12)
                      .frame(height: 240)
                  ProgressView()
              }
          }
    }
}

/*#Preview {
    PreviewView()
}*/
