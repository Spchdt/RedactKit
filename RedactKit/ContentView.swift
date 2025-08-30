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
    @Namespace var ns
    @Query(sort: \Content.timestamp, order: .reverse) private var contents: [Content]
    @State private var openHistoryView: Bool = false
    @StateObject private var piiService = PIIDetectionService()
    @State private var detectedEntities: [PIIEntity] = []
    @State private var inputText = "On 2023-08-28, I received a call from Michael Gordon regarding my recent application. They asked me to verify my information, including my 812-20-5646, and requested my +1-292-255-1722x46579 number for further communication. I provided my address, 591 Bell Radial, Lake Summer, KY 11148, and confirmed my email, danieldavis@example.net, but I hesitated to share my credit card number, 3586258095809562, over the phone."
    
    
    var body: some View {
        ZStack {
            PrismaticMeshBackground()
            
            VStack {
                Button("TEST") {
                    Task {
                        detectedEntities = await piiService.detectPII(in: inputText)
                    }
                }
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
                        UltraGlossyButton(icon: "document.on.document.fill", text: vm.finishedCopied ? "Copied!" : "Copy to Clipboard", font: .headline, width: vm.finishedCopied ? 180 : 250) {
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
                        UltraGlossyButton(icon: vm.startAnalysing ? "progress.indicator" : "sparkles.2", text: vm.startAnalysing ? "Analysing..." : "Paste to Start", font: vm.startAnalysing ? .title3 : .title, width: vm.startAnalysing ? 180 : 320) {
                            withAnimation(.spring(.bouncy)) {
                                vm.startAnalysing.toggle()
                                vm.showHistory = false
                            }
                        }
                        .matchedGeometryEffect(id: "button", in: ns)
                        
                        if !vm.startAnalysing {
                            Button {
                                
                            } label: {
                                HStack {
                                    Image(systemName: "info.circle")
                                    Text("Learn More")
                                }
                                .foregroundStyle(.cyan)
                            }
                            .padding(.bottom, 30)
                        }
                    }
                    
                    
                    if !vm.startAnalysing {
                        ZStack(alignment: .top) {
                            Color.white
                                .clipShape(RoundedRectangle(cornerRadius: 40))
                            
                            Button {
                                withAnimation {
                                    vm.finishedPasting = true
                                }
                            } label: {
                                HStack(spacing: 15) {
                                    Image(systemName: "shield.lefthalf.filled")
                                        .symbolRenderingMode(.hierarchical)
                                    Text("Content Verification")
                                }
                                .fontWeight(.medium)
                                .foregroundColor(.black.opacity(0.5))
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                                .padding(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
                                        .foregroundColor(.black.opacity(0.5))
                                )
                            }
                            .padding(20)
                        }
                        .frame(height: 180)
                        
                        .shadow(color: vm.finishedPasting ? .clear : .cyan.opacity(0.3), radius: 15, x: 0, y: -5)
                    }
                    Spacer()
                        .frame(height: vm.startAnalysing ? 10 : 60)
                }
                .offset(y: !vm.startAnalysing ? 100 : 0)
                //            .padding(.horizontal)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ViewModel())
}
