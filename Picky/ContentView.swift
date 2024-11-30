import SwiftUI

struct ContentView: View {
    @State private var items: [String] = []       // List of stored items
    @State private var newItemText: String = ""  // Text for the pop-up input box
    @State private var showAddItemPopup: Bool = false // Controls the visibility of the add-item pop-up
    @State private var pickedItem: String = ""   // Stores the picked item
    @State private var showPopup: Bool = false   // Controls the visibility of the pick-chit pop-up
    @State private var isLoading: Bool = false   // Controls the loading animation
    @State private var buttonPressed: Bool = false // Tracks button press animation
    @State private var remainingItems: [String] = [] // Tracks items that haven't been picked
    @State private var showClearAllConfirmation: Bool = false // Confirmation for clearing all chits

    let chitsKey = "chitsKey" // Key for storing chits in UserDefaults

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]),
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
                            showAddItemPopup = true // Show add-item pop-up
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

                // Display Items
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(items, id: \.self) { item in
                            HStack {
                                Text(item)
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .padding()
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(gradient: Gradient(colors: [Color.orange, Color.pink]),
                                                       startPoint: .leading,
                                                       endPoint: .trailing))
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.3), radius: 5)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding()
                }

                // Pick Chit Button
                Button(action: {
                    withAnimation {
                        buttonPressed = true
                    }
                    startLoadingAndPickItem()
                }) {
                    Text(isLoading ? "Loading..." : "Pick Chit")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: buttonPressed ? [Color.cyan, Color.green] : [Color.green, Color.cyan]),
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
                .scaleEffect(buttonPressed ? 0.95 : 1.0) // Shrink button slightly when pressed
                .animation(.easeOut(duration: 0.2), value: buttonPressed)
            }

            // Add Item Pop-Up
            if showAddItemPopup {
                VStack(spacing: 20) {
                    Text("Add Items")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                        .padding()

                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 350)
                        .overlay(
                            TextEditor(text: $newItemText)
                                .padding()
                                .foregroundColor(.black)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 5)

                    Button("Add") {
                        withAnimation {
                            buttonPressed = true
                        }
                        addItems()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(gradient: Gradient(colors: [Color.pink, Color.purple]),
                                               startPoint: .leading,
                                               endPoint: .trailing))
                    .foregroundColor(.white)
                    .font(.headline)
                    .cornerRadius(15)
                    .shadow(color: .purple.opacity(0.5), radius: 10)
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

            // Pick Item Pop-Up
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

    // Add items from the pop-up to the list
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
        withAnimation {
            showAddItemPopup = false // Hide pop-up
        }
    }

    // Function to Start Loading and Pick a Random Item
    private func startLoadingAndPickItem() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // Delay for 2 seconds
            pickRandomItem()
            isLoading = false
            buttonPressed = false // Reset button animation
        }
    }

    // Function to Pick a Random Item
    private func pickRandomItem() {
        guard !remainingItems.isEmpty else { return }

        if let randomItem = remainingItems.randomElement() {
            pickedItem = randomItem
            withAnimation {
                remainingItems.removeAll { $0 == randomItem } // Remove the picked item
                showPopup = true // Show pick-chit pop-up
            }
        }
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

