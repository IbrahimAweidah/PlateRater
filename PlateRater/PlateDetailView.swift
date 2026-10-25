import SwiftUI

struct PlateDetailView: View {
    let plate: String
    var store: RatingStore

    @State private var newScore = 5
    @State private var newComment = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var summary: PlateSummary? { store.summary(for: plate) }

    var body: some View {
        List {
            Section {
                HStack {
                    Text(plate)
                        .font(.system(.title, design: .monospaced, weight: .bold))
                    Spacer()
                    if let avg = summary?.average {
                        Label(String(format: "%.1f", avg), systemImage: "star.fill")
                            .foregroundStyle(.yellow)
                            .fontWeight(.semibold)
                    } else if summary == nil && errorMessage == nil {
                        ProgressView()
                    } else {
                        Text("No ratings yet")
                            .foregroundStyle(.secondary)
                    }
                }
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section(summary?.myRating == nil ? "Add a rating" : "Your rating") {
                Picker("Score", selection: $newScore) {
                    ForEach(1...5, id: \.self) { score in
                        Text("\(score) ★").tag(score)
                    }
                }
                .pickerStyle(.segmented)

                TextField("Optional comment", text: $newComment)

                Button(summary?.myRating == nil ? "Submit rating!" : "Update rating") {
                    Task { await save() }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)
            }

            Section("Ratings") {
                let ratings = summary?.ratings ?? []
                if ratings.isEmpty {
                    Text("Be the first to rate this driver.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(ratings) { rating in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                ForEach(1...5, id: \.self) { i in
                                    Image(systemName: i <= rating.score ? "star.fill" : "star")
                                        .foregroundStyle(.yellow)
                                }
                                if rating.isMine {
                                    Text("You")
                                        .font(.caption.bold())
                                        .foregroundStyle(.tint)
                                }
                                Spacer()
                                Text(rating.updatedAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if !rating.comment.isEmpty {
                                Text(rating.comment)
                                    .font(.subheadline)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle(plate)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        do {
            try await store.load(plate)
            errorMessage = nil
            if let mine = summary?.myRating {
                newScore = mine.score
                newComment = mine.comment
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await store.saveRating(score: newScore, comment: newComment, for: plate)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        PlateDetailView(plate: "ABC123", store: RatingStore(auth: AuthManager()))
    }
}
