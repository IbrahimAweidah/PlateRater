import SwiftUI

/// Compete with friends in the hunt. Add each other by the e-mail address of your Google account.
/// Friends only see your first name and which colors and kinds of car you have found, never your plates or ratings.
struct FriendsView: View {
    var auth: AuthManager
    var store: RatingStore

    @State private var email = ""
    @State private var isBusy = false
    @State private var message: String?
    @State private var errorMessage: String?

    private var players: [Player] {
        (store.friends?.players ?? []).sorted { ($0.points, $0.cars) > ($1.points, $1.cars) }
    }

    var body: some View {
        NavigationStack {
            List {
                leaderboard
                requests
                addFriend
            }
            .navigationTitle("Tävla")
            .task { await load() }
            .refreshable { await load() }
            // Your own score comes from your ratings, so refresh when they change.
            .onChange(of: store.mine) { Task { await load() } }
        }
    }

    private var leaderboard: some View {
        Section {
            if store.friends == nil && errorMessage == nil {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                PlayerRow(place: index + 1, player: player)
                    .swipeActions {
                        if let id = player.friendshipId {
                            Button("Ta bort", role: .destructive) { Task { await run { try await store.removeFriend(id) } } }
                        }
                    }
            }
            if players.count == 1 {
                Text("Lägg till en kompis nedan och se vem som hittar flest färger, sorters bilar och märken! 🏁")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Topplista")
        } footer: {
            Text("Poäng för varje färg, sort och märkes bil du har hittat. Kompisar ser bara ditt förnamn och vilka färger, biltyper och märken du hittat, aldrig skyltar eller betyg.")
        }
    }

    @ViewBuilder
    private var requests: some View {
        let incoming = store.friends?.incoming ?? []
        let outgoing = store.friends?.outgoing ?? []
        if !incoming.isEmpty {
            Section("Vill tävla mot dig") {
                ForEach(incoming) { request in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(request.name).font(.headline)
                            if let email = request.email {
                                Text(email).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button("Ja!") { Task { await run { try await store.acceptFriend(request.id) } } }
                            .buttonStyle(.borderedProminent)
                            .tint(Galen.pink)
                        Button("Nej") { Task { await run { try await store.removeFriend(request.id) } } }
                            .buttonStyle(.bordered)
                    }
                }
            }
        }
        if !outgoing.isEmpty {
            Section("Väntar på svar") {
                ForEach(outgoing) { request in
                    HStack {
                        Text(request.email ?? request.name)
                        Spacer()
                        Button("Ångra") { Task { await run { try await store.removeFriend(request.id) } } }
                            .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private var addFriend: some View {
        Section {
            TextField("kompis@gmail.com", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button {
                Task { await sendRequest() }
            } label: {
                Text("Utmana! 🏁")
                    .font(Galen.title(18))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Galen.pink)
            .disabled(isBusy || !email.contains("@"))
            if let message {
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
            if let errorMessage {
                Text(errorMessage).font(.caption).foregroundStyle(.red)
            }
            if let mine = auth.email {
                ShareLink(item: "Tävla mot mig i Galen! Lägg till mig med \(mine) 🤪🚗") {
                    Label("Bjud in en kompis", systemImage: "square.and.arrow.up")
                }
            }
        } header: {
            Text("Lägg till kompis")
        } footer: {
            Text("Skriv adressen till kompisens Google-konto. Kompisen måste ha loggat in i Galen och säga ja innan ni ser varandra.")
        }
    }

    private func load() async {
        do {
            try await store.loadFriends()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func sendRequest() async {
        let address = email.trimmingCharacters(in: .whitespaces)
        await run { try await store.addFriend(email: address) }
        if errorMessage == nil {
            email = ""
            message = "Utmaning skickad till \(address)! 🎉"
        }
    }

    private func run(_ action: () async throws -> Void) async {
        isBusy = true
        defer { isBusy = false }
        message = nil
        do {
            try await action()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct PlayerRow: View {
    let place: Int
    let player: Player

    var body: some View {
        HStack(spacing: 12) {
            Text(medal)
                .font(.title2)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(player.name).font(.headline)
                    if player.isMe {
                        Text("Du").font(.caption.bold()).foregroundStyle(Galen.pink)
                    }
                }
                Text("🎨 \(player.foundColors.count)/\(CarColor.allCases.count) · 🚗 \(player.foundKinds.count)/\(CarKind.allCases.count) · 🏷️ \(player.foundBrands.count)/\(CarBrand.allCases.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(player.points) p")
                .font(Galen.title(20))
        }
        .padding(.vertical, 2)
    }

    private var medal: String {
        switch place {
        case 1: "🥇"
        case 2: "🥈"
        case 3: "🥉"
        default: "\(place)."
        }
    }
}
