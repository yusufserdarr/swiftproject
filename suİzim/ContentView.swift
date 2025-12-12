//
//  ContentView.swift
//  suİzim
//
//  Created by Yusuf Serdaroğlu on 4.12.2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showInputSheet = false
    
    @State private var selection = 0
    
    var body: some View {
        TabView(selection: $selection) {
            DashboardView()
                .tabItem {
                    Label("Özet", systemImage: "drop.fill")
                }
                .tag(0)
            
            StatisticsView()
                .tabItem {
                    Label("İstatistik", systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            ChatbotView()
                .tabItem {
                    Label("Asistan", systemImage: "message.fill")
                }
                .tag(2)
        }
        .overlay(alignment: .bottom) {
            if selection != 2 { // Hide on Chatbot tab
                Button(action: { showInputSheet = true }) {
                    Image(systemName: "plus")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(.bottom, 60)
            }
        }
        .sheet(isPresented: $showInputSheet) {
            ActivityInputView()
                .presentationDetents([.medium])
        }
    }
}
