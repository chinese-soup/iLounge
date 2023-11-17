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

func isImage(text: String) -> Bool {
    /* A dumb way to check if URL could be an image to open in a preview instead of the web browser */
    let letImagePattern = #"(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*\.(?:jpg|jpeg|gif|png))(?:\?([^#]*))?(?:#(.*))?"#
    if text.range(of: letImagePattern, options: [.regularExpression, .caseInsensitive]) != nil {
        return true
    }
    return false
}

func isVideo(text: String) -> Bool {
    /* A dumb way to check if URL could be an image to open in a preview instead of the web browser */
    let letImagePattern = #"(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*\.(?:mp4|mov))(?:\?([^#]*))?(?:#(.*))?"#
    if text.range(of: letImagePattern, options: [.regularExpression, .caseInsensitive]) != nil {
        return true
    }
    return false
}
