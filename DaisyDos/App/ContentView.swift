//
//  ContentView.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]

    var body: some View {
        TabView {
            ModelTestView()
                .tabItem {
                    Label("Test Models", systemImage: "hammer.circle")
                }

            ManagerTestView()
                .tabItem {
                    Label("Test Managers", systemImage: "gearshape.circle")
                }

            ErrorHandlingTestView()
                .tabItem {
                    Label("Test Errors", systemImage: "exclamationmark.triangle.fill")
                }

            DesignSystemTestView()
                .tabItem {
                    Label("Design System", systemImage: "paintpalette.fill")
                }

            NavigationSplitView {
                List {
                    ForEach(tasks) { task in
                        NavigationLink {
                            Text("Task: \(task.title)")
                                .padding()
                            Text("Created: \(task.createdDate, format: Date.FormatStyle(date: .numeric, time: .standard))")
                            Text("Completed: \(task.isCompleted ? "Yes" : "No")")
                        } label: {
                            HStack {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(task.isCompleted ? .green : .gray)
                                Text(task.title)
                                Spacer()
                            }
                        }
                    }
                    .onDelete(perform: deleteTasks)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        Button(action: addTask) {
                            Label("Add Task", systemImage: "plus")
                        }
                    }
                }
            } detail: {
                Text("Select a task")
            }
            .tabItem {
                Label("Tasks", systemImage: "list.bullet")
            }
        }
    }

    private func addTask() {
        withAnimation {
            let newTask = Task(title: "New Task \(Date().formatted(.dateTime.hour().minute()))")
            modelContext.insert(newTask)
        }
    }

    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(tasks[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Task.self, inMemory: true)
}
