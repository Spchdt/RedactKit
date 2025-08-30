//
//  InjectedText.swift
//  RedactKit
//
//  Created by Supachod Trakansirorut on 30/8/25.
//

import SwiftUI
import SwiftData

struct InjectedTextView: View {
    @EnvironmentObject var vm: ViewModel
    @Environment(\.modelContext) private var modelContext
    var ns: Namespace.ID
    @EnvironmentObject var textProcessor : TextProcessor

    var body: some View {
        ZStack(alignment: .top) {
            Color.white
                .blur(radius: 20)
                .clipShape(RoundedRectangle(cornerRadius: 40))
                .matchedGeometryEffect(id: "injectedDoc", in: ns, properties: .frame)
            
            if !vm.finishedPasting {
                Button {
                    if let clipboardText = UIPasteboard.general.string {
                        textProcessor.injectedText = AttributedString(clipboardText)
                    }
                    
                    withAnimation {
                        vm.finishedPasting = true
                    }
                } label: {
                    HStack(spacing: 15) {
                        Image(systemName: "doc.on.clipboard.fill")
                            .symbolRenderingMode(.hierarchical)
                        Text("Tap to Paste")
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

                .padding(20)
            } else {
                ScrollView {
                    Text(textProcessor.injectedText)
                        .foregroundStyle(.black)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .padding()
                        .contentTransition(.numericText())
                    
                    Spacer()
                        .frame(height: 150)
                }
                .onAppear{
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        textProcessor.revertAttributedText {
                            withAnimation {
                                vm.finishedInjecting = true
                            }
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom),
                    removal: .opacity
                ))
                .padding(.top)
                .padding([.top, .horizontal])
            }
            
            if vm.finishedInjecting {
                VStack {
                    Spacer()
                    GlossyButton(icon: "document.on.document.fill", text: "Copy & Save", font: .title3, width: 300) {
                        withAnimation(.none) {
                            vm.startAnalysing = false
                            vm.finishedAnalysing = false
                            
                        }
                        
                        withAnimation {
                            vm.finishedCopied = false
                            vm.finishedPasting = false
                            vm.finishedInjecting = false
                            vm.finishedCopiedInjected = false
                            vm.showHistory = true
                        }
                        
                        saveNewContent(data: textProcessor.injectedText)
                        
                    }
                    .transition(.move(edge: .bottom))
                }
            }
        }
        .frame(maxHeight: vm.finishedPasting ? .infinity : 250)
        .offset(y: vm.finishedPasting ? 0 : 100)
        .shadow(color: vm.finishedPasting ? .clear : .cyan.opacity(0.3), radius: 15, x: 0, y: -5)
        .transition(.move(edge: .bottom))
    }
    
    private func saveNewContent(data: AttributedString) {
        let stringData = String(data.characters)
        let newContent = Content(data: stringData)
        modelContext.insert(newContent)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save: \(error)")
        }
    }

}
