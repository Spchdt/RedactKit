//
//  HistoryView.swift
//  RedactKit
//
//  Created by Supachod Trakansirorut on 30/8/25.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    var contents: [Content]
    
    @State private var showingDeleteAlert = false
    @State private var contentToDelete: Content?
    @State private var showingCopyConfirmation = false
    
    var body: some View {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(contents, id: \.id) { content in
                        ContentCardView(
                            content: content,
                            onDelete: {
                                contentToDelete = content
                                showingDeleteAlert = true
                            },
                            onCopy: {
                                copyToClipboard("\(content.data)")
                            }
                        )
                    }
                }
                .padding()
            }
            .alert("Delete Entry", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    contentToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let content = contentToDelete {
                        deleteContent(content)
                    }
                    contentToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete this entry? This action cannot be undone.")
            }
            .alert("Copied!", isPresented: $showingCopyConfirmation) {
                Button("OK") { }
            } message: {
                Text("Content has been copied to clipboard")
            }
    }
    
    private func deleteContent(_ content: Content) {
        withAnimation(.easeInOut(duration: 0.3)) {
            modelContext.delete(content)
            try? modelContext.save()
        }
    }
    
    private func copyToClipboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
        
        showingCopyConfirmation = true
    }
}

struct ContentCardView: View {
    let content: Content
    let onDelete: () -> Void
    let onCopy: () -> Void
    
    var body: some View {
        Button {
            UIPasteboard.general.string = content.data
        } label: {
            ZStack(alignment: .topTrailing) {
                Color.white
                    .blur(radius: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 40))
                
                ScrollView {
                    Text(content.data)
                }
                .padding()
            }
        }
        .buttonStyle(.plain)
        .frame(height: 150)
    }
}


#Preview {
    ContentView()
        .modelContainer(for: Content.self, inMemory: true)
}
