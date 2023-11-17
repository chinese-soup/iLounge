//
//  Utils.swift
//  ilounge
//
//  Created by Jakub Mach on 16.11.2023.
//

import Foundation
import SwiftUI

struct LoungeText: View {
    let text: String
    @AppStorage("loungeUseMonospaceFont") private var useMonospaceFont: Bool = false

    var body: some View {
        Text(text)
            .font(.system(.body, design: useMonospaceFont == true ? .monospaced : .default))
    }
}
