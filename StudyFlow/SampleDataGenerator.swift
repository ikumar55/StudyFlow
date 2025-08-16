//
//  SampleDataGenerator.swift
//  StudyFlow
//
//  Created by Assistant on 8/14/25.
//

import Foundation
import SwiftData

/// Generates comprehensive sample data for development and testing
class SampleDataGenerator {
    
    /// Creates sample data if none exists
    static func createSampleDataIfNeeded(modelContext: ModelContext) {
        // Check if we already have data
        let descriptor = FetchDescriptor<StudyClass>()
        let existingClasses = (try? modelContext.fetch(descriptor)) ?? []
        
        guard existingClasses.isEmpty else {
            print("Sample data already exists, skipping generation")
            return
        }
        
        print("Creating sample data...")
        createComprehensiveSampleData(modelContext: modelContext)
        
        do {
            try modelContext.save()
            print("Sample data created successfully")
        } catch {
            print("Error saving sample data: \(error)")
        }
    }
    
    /// Forces creation of sample data (used after reset)
    static func createSampleData(modelContext: ModelContext) {
        print("Force creating sample data...")
        createComprehensiveSampleData(modelContext: modelContext)
        
        do {
            try modelContext.save()
            print("Sample data created successfully")
        } catch {
            print("Error saving sample data: \(error)")
        }
    }
    
    private static func createComprehensiveSampleData(modelContext: ModelContext) {
        // Create study classes with different subjects
        let neuralNetworksClass = createNeuralNetworksClass(modelContext: modelContext)
        let swiftUIClass = createSwiftUIClass(modelContext: modelContext)
        let machineLearningClass = createMachineLearningClass(modelContext: modelContext)
        
        // Insert classes
        modelContext.insert(neuralNetworksClass)
        modelContext.insert(swiftUIClass)
        modelContext.insert(machineLearningClass)
    }
    
    // MARK: - Neural Networks Class
    private static func createNeuralNetworksClass(modelContext: ModelContext) -> StudyClass {
        let studyClass = StudyClass(name: "Neural Networks", colorCode: "#4A90E2")
        
        // Lecture 1: Fundamentals
        let fundamentalsLecture = Lecture(
            title: "Neural Network Fundamentals",
            description: "Basic concepts and architecture of neural networks",
            studyClass: studyClass
        )
        
        let fundamentalsCards = [
            ("What is a neural network?", "A computational model inspired by biological neural networks, consisting of interconnected nodes (neurons) that process information through weighted connections."),
            ("What is an activation function?", "A mathematical function that determines the output of a neural network node. Common examples include ReLU, sigmoid, and tanh functions."),
            ("What is backpropagation?", "The algorithm used to train neural networks by calculating gradients and updating weights to minimize the loss function through reverse-mode automatic differentiation."),
            ("What is a perceptron?", "The simplest type of neural network with a single layer that can learn linear decision boundaries for binary classification problems."),
            ("What is the difference between supervised and unsupervised learning?", "Supervised learning uses labeled training data to learn mappings from inputs to outputs, while unsupervised learning finds patterns in data without labels.")
        ]
        
        for (question, answer) in fundamentalsCards {
            let card = Flashcard(question: question, answer: answer, lecture: fundamentalsLecture)
            // Vary the study states and add some history
            if question.contains("neural network") {
                card.studyState = .reviewing
                card.correctCount = 3
                card.totalAttempts = 4
                card.lastStudied = Calendar.current.date(byAdding: .day, value: -2, to: Date())
                card.nextScheduledDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            } else if question.contains("activation") {
                card.studyState = .mastered
                card.correctCount = 8
                card.totalAttempts = 9
                card.lastStudied = Calendar.current.date(byAdding: .day, value: -5, to: Date())
                card.nextScheduledDate = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
            }
            modelContext.insert(card)
        }
        
        // Lecture 2: Deep Learning
        let deepLearningLecture = Lecture(
            title: "Deep Learning Architectures",
            description: "Advanced neural network architectures and techniques",
            studyClass: studyClass
        )
        
        let deepLearningCards = [
            ("What is a Convolutional Neural Network (CNN)?", "A deep learning architecture particularly effective for image processing, using convolutional layers to detect local features through learnable filters."),
            ("What is a Recurrent Neural Network (RNN)?", "A neural network architecture designed for sequential data, where connections form cycles allowing information to persist across time steps."),
            ("What is the vanishing gradient problem?", "A difficulty in training deep networks where gradients become exponentially small as they propagate backward, making it hard to update early layers."),
            ("What is dropout?", "A regularization technique that randomly sets some neurons to zero during training to prevent overfitting and improve generalization."),
            ("What is batch normalization?", "A technique that normalizes inputs to each layer, accelerating training and improving stability by reducing internal covariate shift.")
        ]
        
        for (question, answer) in deepLearningCards {
            let card = Flashcard(question: question, answer: answer, lecture: deepLearningLecture)
            // Most of these are learning state (daily appearance)
            if question.contains("CNN") {
                card.studyState = .learning
                card.correctCount = 1
                card.totalAttempts = 2
                card.lastStudied = Calendar.current.date(byAdding: .hour, value: -6, to: Date())
            }
            modelContext.insert(card)
        }
        
        return studyClass
    }
    
    // MARK: - SwiftUI Class
    private static func createSwiftUIClass(modelContext: ModelContext) -> StudyClass {
        let studyClass = StudyClass(name: "SwiftUI Development", colorCode: "#FF6B35")
        
        let swiftUILecture = Lecture(
            title: "SwiftUI Fundamentals",
            description: "Core concepts of SwiftUI declarative programming",
            studyClass: studyClass
        )
        
        let swiftUICards = [
            ("What is SwiftUI?", "Apple's declarative framework for building user interfaces across all Apple platforms using Swift code."),
            ("What is @State in SwiftUI?", "A property wrapper that allows a view to store and modify local state, automatically updating the UI when the value changes."),
            ("What is the difference between @State and @Binding?", "@State creates and owns a piece of state, while @Binding creates a two-way connection to state owned by another view."),
            ("What is a ViewModifier?", "A protocol that allows you to create reusable modifications that can be applied to views, encapsulating common styling or behavior."),
            ("What is @ObservableObject?", "A protocol for reference types that can notify SwiftUI views when their published properties change, triggering view updates."),
            ("What is the purpose of @Published?", "A property wrapper that automatically publishes changes to a property, notifying any observing views to update."),
            ("How do you create a custom view in SwiftUI?", "Create a struct that conforms to the View protocol and implement the required body property that returns some View.")
        ]
        
        for (i, (question, answer)) in swiftUICards.enumerated() {
            let card = Flashcard(question: question, answer: answer, lecture: swiftUILecture)
            
            // Create variety in study states
            switch i % 4 {
            case 0:
                card.studyState = .learning
                card.correctCount = 0
                card.totalAttempts = 1
            case 1:
                card.studyState = .reviewing
                card.correctCount = 4
                card.totalAttempts = 5
                card.lastStudied = Calendar.current.date(byAdding: .day, value: -1, to: Date())
                card.nextScheduledDate = Date()
            case 2:
                card.studyState = .mastered
                card.correctCount = 7
                card.totalAttempts = 8
                card.lastStudied = Calendar.current.date(byAdding: .day, value: -4, to: Date())
                card.nextScheduledDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
            default:
                card.studyState = .learning
                card.correctCount = 2
                card.totalAttempts = 4
            }
            
            modelContext.insert(card)
        }
        
        return studyClass
    }
    
    // MARK: - Machine Learning Class
    private static func createMachineLearningClass(modelContext: ModelContext) -> StudyClass {
        let studyClass = StudyClass(name: "Machine Learning", colorCode: "#28A745")
        
        let mlBasicsLecture = Lecture(
            title: "ML Fundamentals",
            description: "Core machine learning concepts and algorithms",
            studyClass: studyClass
        )
        
        let mlCards = [
            ("What is machine learning?", "A subset of artificial intelligence that enables computers to learn and make decisions from data without being explicitly programmed for every scenario."),
            ("What is the difference between classification and regression?", "Classification predicts discrete categories or classes, while regression predicts continuous numerical values."),
            ("What is overfitting?", "When a model learns the training data too well, including noise and outliers, resulting in poor performance on new, unseen data."),
            ("What is cross-validation?", "A technique for assessing model performance by dividing data into multiple folds and training/testing on different combinations."),
            ("What is a decision tree?", "A tree-like model that makes decisions by splitting data based on feature values, creating a hierarchical set of if-else conditions."),
            ("What is the bias-variance tradeoff?", "The balance between a model's ability to minimize bias (error from oversimplification) and variance (error from sensitivity to training data)."),
            ("What is feature engineering?", "The process of selecting, modifying, or creating new features from raw data to improve machine learning model performance.")
        ]
        
        for (i, (question, answer)) in mlCards.enumerated() {
            let card = Flashcard(question: question, answer: answer, lecture: mlBasicsLecture)
            
            // Create some overdue cards for testing
            if i < 2 {
                card.studyState = .learning
                card.correctCount = 0
                card.totalAttempts = 1
                card.lastStudied = Calendar.current.date(byAdding: .day, value: -3, to: Date())
                card.nextScheduledDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date() // Overdue
            } else {
                card.studyState = .learning
            }
            
            modelContext.insert(card)
        }
        
        return studyClass
    }
}
