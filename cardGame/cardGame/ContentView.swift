import SwiftUI

@main
struct CardGameApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var pairsCount: Int = 3 // Default to 3 pairs
    @State private var cards: [Card] = []
    @State private var selectedCardIndices: [Int] = []
    @State private var showAlert = false
    @State private var elapsedTime: Int = 0
    @State private var timer: Timer?
    @State private var isGameActive: Bool = false

    var body: some View {
        VStack {
            Text("Memory Card Game")
                .font(.largeTitle)
                .padding()
            
            Picker("Number of Pairs", selection: $pairsCount) {
                ForEach([3, 6, 10], id: \.self) { count in
                    Text("\(count) Pairs")
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            // Displaying cards directly in ContentView
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                    ForEach(cards.indices, id: \.self) { index in
                        if !cards[index].isMatched {
                            CardView(card: cards[index], isFaceUp: selectedCardIndices.contains(index))
                                .onTapGesture {
                                    cardTapped(index)
                                }
                        }
                    }
                }
            }
            .onAppear(perform: setupGame)
            .onChange(of: pairsCount) { _ in setupGame() }

            Button("Start Game") {
                isGameActive = true
                startTimer()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(cards.isEmpty) // Disable button if no cards are generated

            if isGameActive {
                Text("Time: \(elapsedTime) seconds")
                    .font(.headline)
                    .padding()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Congratulations!"), message: Text("You won in \(elapsedTime) seconds!"), dismissButton: .default(Text("OK"), action: resetGame))
        }
        .padding()
        .background(Color.blue.opacity(0.3)) // Light blue background
        .ignoresSafeArea()
    }

    private func setupGame() {
        cards = createCards()
        selectedCardIndices = []
        elapsedTime = 0
        isGameActive = false // Reset game state
    }

    private func createCards() -> [Card] {
        let emojis = ["😃", "🐶", "🚀", "🍕", "🎉", "🌟"] // List of emojis to use as card names
        var generatedCards = [Card]()
        
        for i in 0..<pairsCount {
            let emoji = emojis[i % emojis.count] // Cycle through emojis
            let card = Card(id: i, name: emoji, isMatched: false)
            generatedCards.append(card)
            generatedCards.append(card) // Add a pair
        }
        
        return generatedCards.shuffled()
    }

    private func cardTapped(_ index: Int) {
        guard selectedCardIndices.count < 2,
              !selectedCardIndices.contains(index),
              !cards[index].isMatched else { return }
        
        selectedCardIndices.append(index)

        if selectedCardIndices.count == 2 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkForMatch()
            }
        }
    }

    private func checkForMatch() {
        guard selectedCardIndices.count == 2 else { return }

        let firstIndex = selectedCardIndices[0]
        let secondIndex = selectedCardIndices[1]

        if cards[firstIndex].name == cards[secondIndex].name {
            // Match found
            withAnimation {
                cards[firstIndex].isMatched = true
                cards[secondIndex].isMatched = true
            }
            // Check if the game is won
            if cards.allSatisfy({ $0.isMatched }) {
                showAlert = true
                isGameActive = false
                timer?.invalidate() // Stop the timer
            }
        } else {
            // No match, flip back with a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    selectedCardIndices.removeAll()
                }
            }
        }
        selectedCardIndices.removeAll()
    }

    private func resetGame() {
        setupGame()
        isGameActive = false
    }

    private func startTimer() {
        timer?.invalidate() // Invalidate any existing timer
        elapsedTime = 0 // Reset elapsed time
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
        }
    }
}

// Card View for displaying each card
struct CardView: View {
    var card: Card
    var isFaceUp: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(isFaceUp ? Color.white : Color.blue)
                .frame(width: 70, height: 100)
                .cornerRadius(10)
                .shadow(radius: 5)
                .transition(.opacity)

            if isFaceUp {
                Text(card.name) // Show the emoji when the card is face up
                    .font(.largeTitle)
                    .foregroundColor(.black)
            } else {
                Text("🃏") // Show a placeholder emoji on the back
                    .font(.largeTitle)
                    .frame(width: 70, height: 100)
                    .foregroundColor(.white)
            }
        }
        .rotation3DEffect(isFaceUp ? Angle(degrees: 0) : Angle(degrees: 180), axis: (0, 1, 0))
        .animation(.easeInOut, value: isFaceUp)
    }
}

// Card Model
struct Card: Identifiable {
    let id: Int
    let name: String
    var isMatched: Bool = false
}
