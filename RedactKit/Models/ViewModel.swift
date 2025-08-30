//
//  ViewModel.swift
//  RedactKit
//
//  Created by Supachod Trakansirorut on 30/8/25.
//

import SwiftUI

class ViewModel: ObservableObject {
    @Published var startAnalysing: Bool = false
    @Published var finishedAnalysing: Bool = false
    @Published var finishedCopied: Bool = false
    @Published var finishedPasting: Bool = false
    @Published var finishedInjecting: Bool = false
    @Published var finishedCopiedInjected: Bool = false
    
    @Published var showHistory: Bool = true
}
