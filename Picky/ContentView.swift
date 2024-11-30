import SwiftUI

struct ContentView: View {
    @State private var items: [String] = []       // List of stored items
    @State private var newItemText: String = ""  // Text for the add-item popup
    @State private var showAddItemPopup: Bool = false // Controls the visibility of the add-item popup
    @State private var pickedItem: String = ""   // Stores the picked item
    @State private var showPopup: Bool = false   // Controls the visibility of the pick-chit popup
    @State private var isLoading: Bool = false   // Controls the loading animation
    @State private var remainingItems: [String] = [] // Tracks items that haven't been picked
    @State private var showClearAllConfirmation: Bool = false // Confirmation for clearing all chits
    @State private var editingItemIndex: Int? = nil // Index of the item being edited
    @State private var editedText: String = ""   // Stores the edited text

    let chitsKey = "chitsKey" // Key for storing chits in UserDefaults

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(gradient: Gradient(colors: [Color.indigo, Color.black]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            // Main Content
            VStack {
                // Top Bar with Title, Plus Icon, and Trashcan Icon
                HStack {
                    Text("Chitty Picky Bang-Bang!")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        withAnimation {
                            showAddItemPopup = true // Show add-item popup
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .shadow(color: .white.opacity(0.5), radius: 10)
                    }
                    .padding(.trailing, 10)

                    Button(action: {
                        showClearAllConfirmation = true // Show confirmation dialog
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .shadow(color: .red.opacity(0.5), radius: 10)
                    }
                }
                .padding()

                // Display Items with Swipe-to-Delete
                List {
                    ForEach(items.indices, id: \.self) { index in
                        HStack {
                            Text(items[index])
                                .foregroundColor(.white)
                                .font(.headline)
                                .padding()
                            Spacer()
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.indigo]),
                                                     startPoint: .leading,
                                                     endPoint: .trailing))
                        )
                        .onTapGesture {
                            editingItemIndex = index
                            editedText = items[index]
                        }
                    }
                    .onDelete(perform: deleteItems)
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)

                // Pick Chit Button
                Button(action: {
                    withAnimation {
                        startLoadingAndPickItem()
                    }
                }) {
                    Text(isLoading ? "Loading..." : "Pick Chit")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.cyan]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(color: .cyan.opacity(0.5), radius: 10)
                        .font(.headline)
                }
                .disabled(remainingItems.isEmpty || isLoading) // Disable if no items or loading
                .padding()
            }

            // Add Item Popup
            if showAddItemPopup {
                VStack(spacing: 20) {
                    Text("Add Items")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                        .padding()

                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 120)
                        .overlay(
                            TextEditor(text: $newItemText)
                                .padding()
                                .foregroundColor(.black)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 5)

                    HStack(spacing: 15) {
                        // Cancel Button
                        Button("Cancel") {
                            withAnimation {
                                showAddItemPopup = false
                                newItemText = ""
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.5), radius: 5)

                        // Add Button
                        Button("Add") {
                            withAnimation {
                                addItems()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(gradient: Gradient(colors: [Color.pink, Color.purple]),
                                                   startPoint: .leading,
                                                   endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(color: .purple.opacity(0.5), radius: 10)
                    }
                }
                .padding()
                .frame(width: 320)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.8), Color.blue.opacity(0.5)]),
                                             startPoint: .top,
                                             endPoint: .bottom))
                )
                .shadow(color: .black.opacity(0.5), radius: 20)
                .transition(.scale.combined(with: .opacity))
            }

            // Edit Item Popup
            if let index = editingItemIndex {
                VStack(spacing: 20) {
                    Text("Edit Item")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                        .padding()

                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 120)
                        .overlay(
                            TextEditor(text: $editedText)
                                .padding()
                                .foregroundColor(.black)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 5)

                    HStack(spacing: 15) {
                        // Cancel Button
                        Button("Cancel") {
                            withAnimation {
                                editingItemIndex = nil
                                editedText = ""
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(15)

                        // Save Button
                        Button("Save") {
                            withAnimation {
                                if index >= 0 && index < items.count {
                                    items[index] = editedText
                                    remainingItems = items
                                    saveItems()
                                    editingItemIndex = nil
                                    editedText = ""
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(gradient: Gradient(colors: [Color.pink, Color.purple]),
                                                   startPoint: .leading,
                                                   endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(color: .purple.opacity(0.5), radius: 10)
                    }
                }
                .padding()
                .frame(width: 320)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.8), Color.blue.opacity(0.5)]),
                                             startPoint: .top,
                                             endPoint: .bottom))
                )
                .shadow(color: .black.opacity(0.5), radius: 20)
                .transition(.scale.combined(with: .opacity))
            }

            // Pick Item Popup
            if showPopup {
                VStack(spacing: 20) {
                    Text("Your Random Pick")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top)

                    Text(pickedItem)
                        .font(.largeTitle)
                        .bold()
                        .padding()
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)

                    Button("Close") {
                        withAnimation {
                            showPopup = false
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange]),
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing))
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .shadow(color: .orange.opacity(0.5), radius: 10)
                }
                .padding()
                .frame(width: 320)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                )
                .shadow(color: .purple.opacity(0.5), radius: 20)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            loadItems() // Load saved items on app launch
        }
        .alert(isPresented: $showClearAllConfirmation) {
            Alert(
                title: Text("Clear All Chits"),
                message: Text("Are you sure you want to clear all chits?"),
                primaryButton: .destructive(Text("Clear")) {
                    clearAllChits()
                },
                secondaryButton: .cancel()
            )
        }
    }

    // Add items from the popup to the list
    private func addItems() {
        let newItems = newItemText
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        withAnimation {
            items.append(contentsOf: newItems)
            remainingItems.append(contentsOf: newItems) // Update remaining items
        }
        saveItems() // Save the updated items
        newItemText = ""
        showAddItemPopup = false // Hide popup
    }

    // Function to Start Loading and Pick a Random Item
    private func startLoadingAndPickItem() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // Delay for 2 seconds
            pickRandomItem()
            isLoading = false
        }
    }

    // Function to Pick a Random Item
    private func pickRandomItem() {
        guard !remainingItems.isEmpty else { return }

        if let randomItem = remainingItems.randomElement() {
            pickedItem = randomItem
            withAnimation {
                remainingItems.removeAll { $0 == randomItem } // Remove the picked item
                showPopup = true // Show pick-chit popup
            }
        }
    }

    // Delete items with swipe
    private func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        remainingItems = items
        saveItems()
    }

    // Function to Clear All Chits
    private func clearAllChits() {
        withAnimation {
            items.removeAll()
            remainingItems.removeAll()
        }
        saveItems() // Save the cleared state
    }

    // Save items to UserDefaults
    private func saveItems() {
        UserDefaults.standard.set(items, forKey: chitsKey)
    }

    // Load items from UserDefaults
    private func loadItems() {
        if let savedItems = UserDefaults.standard.stringArray(forKey: chitsKey) {
            items = savedItems
            remainingItems = savedItems
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

