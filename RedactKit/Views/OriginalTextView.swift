//
//  LongTextScrollView.swift
//  RedactKit
//
//  Created by Supachod Trakansirorut on 29/8/25.
//

import SwiftUI

struct OriginalTextView: View {
    @EnvironmentObject var vm: ViewModel
    @State private var redactText: Bool = false
    @EnvironmentObject var textProcessor : TextProcessor
    
    var body: some View {
        ZStack {
            Color.white
                .blur(radius: 20)
                .clipShape(RoundedRectangle(cornerRadius: 40))
            
            ScrollView {
                Text(textProcessor.originalText)
                    .foregroundStyle(.black)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .padding()
                    .contentTransition(.numericText())
                
                Spacer()
                    .frame(height: 150)
            }
            .padding(.top)
            .padding([.top, .horizontal])
        }
        .frame(maxHeight: vm.finishedAnalysing ? 200 : .infinity)
        .padding(vm.finishedAnalysing ? 20 : 0)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                textProcessor.changeAttributedText {
                    withAnimation {
                        vm.finishedAnalysing = true
                    }
                }
            }
        }
    }
}
