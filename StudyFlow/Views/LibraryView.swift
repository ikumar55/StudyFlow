//
//  LibraryView.swift
//  StudyFlow
//
//  Created by Idhant Kumar on 8/14/25.
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var studyClasses: [StudyClass]
    
    @State private var showingAddClass = false
    @State private var newClassName = ""
    @State private var selectedColorCode = "#4A90E2"
    
    // Predefined color options for classes
    private let classColors = [
        "#4A90E2", // Blue
        "#FF6B35", // Orange
        "#28A745", // Green
        "#DC3545", // Red
        "#6F42C1", // Purple
        "#FD7E14", // Orange-Yellow
        "#20C997", // Teal
        "#E83E8C"  // Pink
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                if studyClasses.isEmpty {
                    emptyStateView
                } else {
                    classListView
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Class") {
                        showingAddClass = true
                    }
                }
            }
            .sheet(isPresented: $showingAddClass) {
                addClassSheet
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Study Classes")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first class to start adding flashcards")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create First Class") {
                showingAddClass = true
            }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var classListView: some View {
        List {
            ForEach(studyClasses) { studyClass in
                NavigationLink(destination: ClassDetailView(studyClass: studyClass)) {
                    ClassRowView(studyClass: studyClass, onEdit: { editClass(studyClass) }, onDelete: { deleteClass(studyClass) })
                }
            }
            .onDelete(perform: deleteClasses)
        }
    }
    
    // MARK: - Add Class Sheet
    private var addClassSheet: some View {
        NavigationStack {
            Form {
                Section("Class Details") {
                    TextField("Class Name", text: $newClassName)
                        .textInputAutocapitalization(.words)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(classColors, id: \.self) { colorCode in
                            Button(action: { selectedColorCode = colorCode }) {
                                Circle()
                                    .fill(Color(hex: colorCode) ?? Color.blue)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColorCode == colorCode ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        resetAddClassForm()
                        showingAddClass = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addNewClass()
                    }
                    .disabled(newClassName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func addNewClass() {
        let trimmedName = newClassName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let newClass = StudyClass(name: trimmedName, colorCode: selectedColorCode)
        modelContext.insert(newClass)
        
        try? modelContext.save()
        resetAddClassForm()
        showingAddClass = false
    }
    
    private func resetAddClassForm() {
        newClassName = ""
        selectedColorCode = "#4A90E2"
    }
    
    private func editClass(_ studyClass: StudyClass) {
        // TODO: Implement edit functionality
        print("Edit class: \(studyClass.name)")
    }
    
    private func deleteClass(_ studyClass: StudyClass) {
        modelContext.delete(studyClass)
        try? modelContext.save()
    }
    
    private func deleteClasses(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(studyClasses[index])
            }
        }
    }
}

struct ClassRowView: View {
    let studyClass: StudyClass
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingOptions = false
    @State private var showingDeleteAlert = false
    @State private var showingEditDialog = false
    @State private var editedName = ""
    
    var body: some View {
        HStack {
            // Class color indicator
            Circle()
                .fill(Color(hex: studyClass.colorCode) ?? Color.blue)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(studyClass.name)
                    .font(.headline)
                
                Text("\(studyClass.activeFlashcards) active cards")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Three dots menu
            Button(action: { showingOptions = true }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
        .confirmationDialog("Class Options", isPresented: $showingOptions, titleVisibility: .visible) {
            Button("Rename") {
                editedName = studyClass.name
                showingEditDialog = true
            }
            Button("Delete", role: .destructive) {
                showingDeleteAlert = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Delete Class", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete '\(studyClass.name)'? This will also delete all lectures and flashcards in this class.")
        }
        .alert("Rename Class", isPresented: $showingEditDialog) {
            TextField("Class Name", text: $editedName)
            Button("Cancel", role: .cancel) {
                editedName = ""
            }
            Button("Save") {
                if !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    studyClass.name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                    try? studyClass.modelContext?.save()
                }
                editedName = ""
            }
            .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Enter a new name for this class")
        }
    }
}



#Preview {
    LibraryView()
}