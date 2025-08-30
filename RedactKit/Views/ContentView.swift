//
//  ContentView.swift
//  RedactKit
//
//  Created by Supachod Trakansirorut on 29/8/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var vm: ViewModel
    @EnvironmentObject var textProcessor : TextProcessor
    @Namespace var ns
    @Query(sort: \Content.timestamp, order: .reverse) private var contents: [Content]
    @State private var openHistoryView: Bool = false
    @StateObject private var piiService = PIIDetectionService()
    
    
    var body: some View {
        ZStack {
            PrismaticMeshBackground()
            
            VStack {
                HStack {
                    Spacer()
                    if vm.showHistory {
                        Button {
                            withAnimation {
                                openHistoryView.toggle()
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .foregroundStyle(.white)
                                    .frame(width: 25, height: 30)
                                    .shadow(color: Color.cyan.opacity(0.3), radius: 8, x: 0, y: 4)
                                    .rotationEffect(.degrees(10))
                                    .offset(x: 17, y:-3)
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .foregroundStyle(.white)
                                    .frame(width: 25, height: 30)
                                    .shadow(color: Color.cyan.opacity(0.3), radius: 8, x: 0, y: 4)
                                    .rotationEffect(.degrees(-10))
                                    .matchedGeometryEffect(id: "injectedDoc", in: ns)
                            }
                            .padding(.horizontal, 50)
                            .padding(.top)}
                    }
                }
                Spacer()
            }
            
            if !vm.finishedAnalysing {
                
                VStack {
                    Image("redactKitLogo")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(.black.opacity(0.8))
                        .frame(width: 200)
                        .matchedGeometryEffect(id: "logo", in: ns)
                    Spacer()
                    
                    if openHistoryView {
                        HistoryView(contents: contents)
                            .padding(.top, 10)
                            .transition(.move(edge: .trailing))
                    }
                }
                .padding(.top, openHistoryView ? 40 : 150)
                .padding(.horizontal)
            }
            
            if !openHistoryView {
                VStack {
                    if vm.finishedAnalysing {
                        Image("redactKitLogo")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(.black.opacity(0.8))
                            .frame(width: 200)
                            .matchedGeometryEffect(id: "logo", in: ns)
                            .padding(.top, 40)
                    }
                    if vm.startAnalysing {
                        OriginalTextView()
                            .foregroundStyle(.white)
                            .transition(.move(edge: .bottom))
                    }
                    if vm.finishedAnalysing {
                        GlossyButton(icon: "document.on.document.fill", text: vm.finishedCopied ? "Copied!" : "Copy to Clipboard", font: .headline, width: vm.finishedCopied ? 180 : 250) {
                            let stringData = String(textProcessor.originalText.characters)
                            UIPasteboard.general.string = stringData

                            withAnimation() {
                                vm.finishedCopied = true
                            }
                        }

                        .matchedGeometryEffect(id: "button", in: ns)
                        Spacer()
                    }
                }
                
                VStack {
                    Spacer()
                    if vm.finishedCopied && !vm.finishedCopiedInjected {
                        InjectedTextView(ns: ns)
                    }
                }
                
                VStack {
                    Spacer()
                    if !vm.finishedAnalysing {
                        GlossyButton(icon: vm.startAnalysing ? "progress.indicator" : "sparkles.2", text: vm.startAnalysing ? "Analysing..." : "Paste to Start", font: vm.startAnalysing ? .title3 : .title, width: vm.startAnalysing ? 180 : 320) {
                            if let clipboardText = UIPasteboard.general.string {
                                textProcessor.originalText = AttributedString(clipboardText)
                                
                                Task {
                                    textProcessor.currentReplacements = await piiService.getPIIMapping(from: clipboardText)
                                    print(textProcessor.currentReplacements)
                                }
                                
                                withAnimation(.spring(.bouncy)) {
                                    vm.startAnalysing.toggle()
                                    vm.showHistory = false
                                }
                            }
                        }
                        .matchedGeometryEffect(id: "button", in: ns)
                        
                        if !vm.startAnalysing {
                            Button {
                                if let url = URL(string: "https://devpost.com/software/redactkit") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "info.circle")
                                    Text("Learn More")
                                }
                                .foregroundStyle(.cyan)
                            }
                            .padding(.top, 5)
                            .padding(.bottom, 30)
                        }
                    }
                    
                    Spacer()
                        .frame(height: vm.startAnalysing ? 10 : 60)
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ViewModel())
}
