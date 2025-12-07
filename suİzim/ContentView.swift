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
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Özet", systemImage: "drop.fill")
                }
            
            StatisticsView()
                .tabItem {
                    Label("İstatistik", systemImage: "chart.bar.fill")
                }
            
            ChatbotView()
                .tabItem {
                    Label("Asistan", systemImage: "message.fill")
                }
        }
        .overlay(alignment: .bottom) {
            Button(action: { showInputSheet = true }) {
                Image(systemName: "plus")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(.bottom, 60) // Adjust based on TabBar height
        }
        .sheet(isPresented: $showInputSheet) {
            ActivityInputView()
                .presentationDetents([.medium])
        }
    }
}
