//
//  PhotoTestView.swift
//  StudyFlow
//
//  Created by Assistant on 11/10/25.
//

import SwiftUI

/// Test view to demonstrate photo functionality in simulator
struct PhotoTestView: View {
    @State private var questionPhotos: [String] = []
    @State private var answerPhotos: [String] = []
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    PhotoPicker(photos: $questionPhotos, title: "Question Photos")
                }
                
                Section {
                    PhotoPicker(photos: $answerPhotos, title: "Answer Photos")
                }
                
                Section("Photo Summary") {
                    HStack {
                        Text("Question Photos:")
                        Spacer()
                        Text("\(questionPhotos.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Answer Photos:")
                        Spacer()
                        Text("\(answerPhotos.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    if !questionPhotos.isEmpty || !answerPhotos.isEmpty {
                        Button("View All Photos") {
                            // This would show PhotoViewer in real implementation
                            print("Would show PhotoViewer with photos")
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Photo System Test")
        }
    }
}

#Preview {
    PhotoTestView()
}
