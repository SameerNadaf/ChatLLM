//
//  LottieView.swift
//  ChatLLM
//
//  Created Sameer on 02/12/25.
//

import SwiftUI
import Lottie

struct LottieAnimationView: View {
    let fileName: String
    let title: String
    
    var body: some View {
        VStack(spacing: 20) {
            LottieView(animation: .named(fileName))
                .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
            
            Text(title)
                .font(.title3)
                .bold()
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 500)
    }
}

#Preview {
    LottieAnimationView(fileName: "emptyGhost.json", title: "No Data")
}
