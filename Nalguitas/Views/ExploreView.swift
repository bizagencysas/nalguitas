import SwiftUI

struct ExploreView: View {
    let isAdmin: Bool
    @State private var daysTogether: DaysTogether?
    @State private var todayQuestion: DailyQuestion?
    @State private var todayMood: MoodEntry?
    @State private var coupons: [LoveCoupon] = []
    @State private var achievements: [Achievement] = []
    @State private var songs: [Song] = []
    @State private var specialDates: [SpecialDate] = []
    @State private var showMoodPicker = false
    @State private var showCoupons = false
    @State private var showAchievements = false
    @State private var showSongs = false
    @State private var questionAnswer = ""
    @State private var isAnswering = false
    @State private var moodNote = ""
    
    // Song sharing
    @State private var showSongSheet = false
    @State private var songUrl = ""
    @State private var songTitle = ""
    @State private var songArtist = ""
    @State private var songMessage = ""
    @State private var isSendingSong = false
    
    // Coupon creation (admin)
    @State private var showCouponSheet = false
    @State private var couponTitle = ""
    @State private var couponDescription = ""
    @State private var couponEmoji = "🎟️"
    @State private var isCreatingCoupon = false
    
    @State private var toastText: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.meshBackground
                
                ScrollView {
                    VStack(spacing: 20) {
                        Spacer(minLength: 10)
                        
                        // Days Together Counter
                        if let days = daysTogether {
                            daysCounterCard(days)
                        }
                        
                        // Mood Tracker
                        moodCard
                        
                        // Daily Question
                        if let question = todayQuestion, question.id != nil {
                            questionCard(question)
                        }
                        
                        // Quick Actions Grid
                        quickActionsGrid
                        
                        // Upcoming Dates
                        if !specialDates.isEmpty {
                            upcomingDatesCard
                        }
                        
                        // Recent Songs
                        if !songs.isEmpty {
                            recentSongsCard
                        }
                        
                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 20)
                }
                .scrollIndicators(.hidden)
                
                if let toast = toastText {
                    VStack {
                        Spacer()
                        Text(toast)
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Theme.rosePrimary))
                            .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Explorar")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCoupons) { CouponsSheetView(isAdmin: isAdmin, coupons: coupons, onRefresh: loadData) }
            .sheet(isPresented: $showAchievements) { AchievementsSheetView(achievements: achievements) }
            .sheet(isPresented: $showSongSheet) { songShareSheet }
            .sheet(isPresented: $showCouponSheet) { couponCreateSheet }
            .task { await loadData() }
        }
    }
    
    // MARK: - Days Counter
    private func daysCounterCard(_ days: DaysTogether) -> some View {
        VStack(spacing: 12) {
            Text("💕")
                .font(.system(size: 40))
            
            Text("\(days.totalDays)")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [Theme.rosePrimary, Theme.roseQuartz], startPoint: .leading, endPoint: .trailing)
                )
            
            Text("días juntos")
                .font(.system(.title3, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 16) {
                VStack { Text("\(days.years)").font(.system(.title2, design: .rounded, weight: .bold)).foregroundStyle(Theme.rosePrimary); Text("años").font(.caption).foregroundStyle(.secondary) }
                VStack { Text("\(days.months)").font(.system(.title2, design: .rounded, weight: .bold)).foregroundStyle(Theme.rosePrimary); Text("meses").font(.caption).foregroundStyle(.secondary) }
                VStack { Text("\(days.days)").font(.system(.title2, design: .rounded, weight: .bold)).foregroundStyle(Theme.rosePrimary); Text("días").font(.caption).foregroundStyle(.secondary) }
            }
            
            Text("Desde el 2 de Mayo de 2021")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial).shadow(color: Theme.rosePrimary.opacity(0.15), radius: 12, y: 4))
    }
    
    // MARK: - Mood Card
    private var moodCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("¿Cómo te sientes hoy?", systemImage: "heart.circle")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.rosePrimary)
                Spacer()
                if let mood = todayMood {
                    Text(mood.emoji).font(.title)
                }
            }
            
            if todayMood != nil {
                HStack(spacing: 6) {
                    Text("Hoy te sientes:").font(.subheadline).foregroundStyle(.secondary)
                    Text(todayMood!.mood).font(.system(.subheadline, design: .rounded, weight: .semibold)).foregroundStyle(Theme.rosePrimary)
                    if let note = todayMood?.note, !note.isEmpty {
                        Text("— \(note)").font(.caption).foregroundStyle(.tertiary).lineLimit(1)
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MoodOption.options) { option in
                            Button {
                                Task { await selectMood(option) }
                            } label: {
                                VStack(spacing: 2) {
                                    Text(option.emoji).font(.system(size: 28))
                                    Text(option.mood).font(.system(.caption2, design: .rounded)).foregroundStyle(.secondary)
                                }
                                .frame(width: 60, height: 55)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).shadow(color: Theme.rosePrimary.opacity(0.1), radius: 8, y: 3))
    }
    
    // MARK: - Question Card
    private func questionCard(_ q: DailyQuestion) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Pregunta del Día", systemImage: "bubble.left.and.bubble.right")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.rosePrimary)
                Spacer()
                Text(q.category ?? "").font(.caption).foregroundStyle(.secondary).padding(.horizontal, 8).padding(.vertical, 2).background(Capsule().fill(Theme.rosePrimary.opacity(0.1)))
            }
            
            Text(q.question)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(Color(red: 0.30, green: 0.20, blue: 0.22))
            
            if q.answered == true, let answer = q.answer {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
                    Text(answer).font(.system(.subheadline, design: .rounded)).foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    TextField("Tu respuesta...", text: $questionAnswer, axis: .vertical)
                        .lineLimit(2...3)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.6)))
                    
                    Button {
                        Task { await submitAnswer(q) }
                    } label: {
                        Image(systemName: isAnswering ? "hourglass" : "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.rosePrimary)
                    }
                    .disabled(questionAnswer.isEmpty || isAnswering)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).shadow(color: Theme.rosePrimary.opacity(0.1), radius: 8, y: 3))
    }
    
    // MARK: - Quick Actions
    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            quickAction(icon: "🎟️", title: "Cupones", count: coupons.filter { !$0.redeemed }.count) { showCoupons = true }
            quickAction(icon: "🏆", title: "Logros", count: achievements.filter { $0.unlocked }.count) { showAchievements = true }
            quickAction(icon: "🎵", title: "Canciones", count: songs.count) { showSongSheet = true }
            if isAdmin {
                quickAction(icon: "🎟️✨", title: "Crear Cupón", count: nil) { showCouponSheet = true }
            }
        }
    }
    
    private func quickAction(icon: String, title: String, count: Int?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(icon).font(.system(size: 28))
                Text(title).font(.system(.caption, design: .rounded, weight: .semibold)).foregroundStyle(Color(red: 0.30, green: 0.20, blue: 0.22))
                if let count = count { Text("\(count)").font(.system(.caption2, design: .rounded, weight: .bold)).foregroundStyle(Theme.rosePrimary) }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial).shadow(color: Theme.rosePrimary.opacity(0.05), radius: 4, y: 2))
        }
    }
    
    // MARK: - Upcoming Dates
    private var upcomingDatesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Fechas Especiales", systemImage: "calendar.badge.clock")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.rosePrimary)
            
            ForEach(specialDates) { d in
                HStack {
                    Text(d.emoji).font(.title2)
                    VStack(alignment: .leading) {
                        Text(d.title).font(.system(.subheadline, design: .rounded, weight: .semibold))
                        Text(d.date).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    let daysUntil = daysUntilDate(d.date)
                    if daysUntil >= 0 {
                        Text("en \(daysUntil) días").font(.system(.caption, design: .rounded, weight: .bold)).foregroundStyle(Theme.rosePrimary)
                    } else {
                        Text("pasó").font(.caption).foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).shadow(color: Theme.rosePrimary.opacity(0.1), radius: 8, y: 3))
    }
    
    // MARK: - Recent Songs
    private var recentSongsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Canciones Compartidas", systemImage: "music.note.list")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.rosePrimary)
            
            ForEach(songs.prefix(3)) { s in
                Button {
                    if let url = URL(string: s.youtubeUrl) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "play.circle.fill").font(.title2).foregroundStyle(Color.red)
                        VStack(alignment: .leading) {
                            Text(s.title.isEmpty ? "🎵 Canción" : s.title).font(.system(.subheadline, design: .rounded, weight: .semibold)).foregroundStyle(.primary)
                            if !s.artist.isEmpty { Text(s.artist).font(.caption).foregroundStyle(.secondary) }
                            if !s.message.isEmpty { Text(s.message).font(.caption2).foregroundStyle(.tertiary).lineLimit(1) }
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).shadow(color: Theme.rosePrimary.opacity(0.1), radius: 8, y: 3))
    }
    
    // MARK: - Song Share Sheet
    private var songShareSheet: some View {
        NavigationStack {
            ZStack {
                Theme.meshBackground
                VStack(spacing: 16) {
                    TextField("Link de YouTube", text: $songUrl).textFieldStyle(.roundedBorder)
                    TextField("Título de la canción", text: $songTitle).textFieldStyle(.roundedBorder)
                    TextField("Artista", text: $songArtist).textFieldStyle(.roundedBorder)
                    TextField("Mensaje (opcional)", text: $songMessage).textFieldStyle(.roundedBorder)
                    
                    Button { Task { await shareSong() } } label: {
                        HStack {
                            if isSendingSong { ProgressView().tint(.white) } else { Image(systemName: "music.note"); Text("Compartir Canción") }
                        }
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [Theme.rosePrimary, Theme.roseQuartz], startPoint: .leading, endPoint: .trailing)))
                    }
                    .disabled(songUrl.isEmpty || isSendingSong)
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Compartir Canción 🎵")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { showSongSheet = false } } }
        }
    }
    
    // MARK: - Coupon Create Sheet
    private var couponCreateSheet: some View {
        NavigationStack {
            ZStack {
                Theme.meshBackground
                VStack(spacing: 16) {
                    let emojis = ["🎟️", "🍽️", "💆", "🎬", "🍦", "☕", "💐", "🎮", "🛍️", "💋", "🧸", "🎂"]
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(emojis, id: \.self) { e in
                                Button { couponEmoji = e } label: {
                                    Text(e).font(.title).padding(8).background(Circle().fill(couponEmoji == e ? Theme.rosePrimary.opacity(0.2) : Color.clear)).overlay(Circle().stroke(couponEmoji == e ? Theme.rosePrimary : Color.clear, lineWidth: 2))
                                }
                            }
                        }
                    }
                    TextField("Título del cupón (ej: Cena gratis)", text: $couponTitle).textFieldStyle(.roundedBorder)
                    TextField("Descripción (ej: Vale por una cena romántica)", text: $couponDescription).textFieldStyle(.roundedBorder)
                    
                    Button { Task { await createCoupon() } } label: {
                        HStack {
                            if isCreatingCoupon { ProgressView().tint(.white) } else { Image(systemName: "gift"); Text("Crear Cupón") }
                        }
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [Theme.rosePrimary, Theme.roseQuartz], startPoint: .leading, endPoint: .trailing)))
                    }
                    .disabled(couponTitle.isEmpty || isCreatingCoupon)
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Crear Cupón de Amor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { showCouponSheet = false } } }
        }
    }
    
    // MARK: - Actions
    private func loadData() async {
        async let d = try? APIService.shared.fetchDaysTogether()
        async let q = try? APIService.shared.fetchTodayQuestion()
        async let m = try? APIService.shared.fetchTodayMood()
        async let c = try? APIService.shared.fetchCoupons()
        async let a = try? APIService.shared.fetchAchievements()
        async let s = try? APIService.shared.fetchSongs()
        async let dates = try? APIService.shared.fetchSpecialDates()
        
        let (days, question, mood, cps, achs, sgs, dts) = await (d, q, m, c, a, s, dates)
        daysTogether = days
        todayQuestion = question
        todayMood = mood
        coupons = cps ?? []
        achievements = achs ?? []
        songs = sgs ?? []
        specialDates = dts ?? []
    }
    
    private func selectMood(_ option: MoodOption) async {
        do {
            try await APIService.shared.saveMood(mood: option.mood, emoji: option.emoji, note: nil)
            todayMood = MoodEntry(id: "now", mood: option.mood, emoji: option.emoji, note: nil, createdAt: nil)
            showToast("Mood guardado \(option.emoji)")
        } catch {}
    }
    
    private func submitAnswer(_ q: DailyQuestion) async {
        guard let id = q.id, !questionAnswer.isEmpty else { return }
        isAnswering = true
        defer { isAnswering = false }
        do {
            try await APIService.shared.answerQuestion(id: id, answer: questionAnswer)
            todayQuestion = DailyQuestion(id: id, question: q.question, category: q.category, answered: true, answer: questionAnswer, answeredAt: nil, shownDate: nil)
            questionAnswer = ""
            showToast("¡Respuesta enviada! 💕")
        } catch {}
    }
    
    private func shareSong() async {
        isSendingSong = true
        defer { isSendingSong = false }
        do {
            try await APIService.shared.sendSong(youtubeUrl: songUrl, title: songTitle, artist: songArtist, message: songMessage, fromGirlfriend: !isAdmin)
            showSongSheet = false
            songUrl = ""; songTitle = ""; songArtist = ""; songMessage = ""
            showToast("¡Canción compartida! 🎵")
            await loadData()
        } catch {}
    }
    
    private func createCoupon() async {
        isCreatingCoupon = true
        defer { isCreatingCoupon = false }
        do {
            try await APIService.shared.createCoupon(title: couponTitle, description: couponDescription, emoji: couponEmoji)
            showCouponSheet = false
            couponTitle = ""; couponDescription = ""
            showToast("¡Cupón creado! 🎟️")
            await loadData()
        } catch {}
    }
    
    private func daysUntilDate(_ dateStr: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return -1 }
        var nextDate = date
        let now = Date()
        while nextDate < now { nextDate = Calendar.current.date(byAdding: .year, value: 1, to: nextDate) ?? nextDate }
        return Calendar.current.dateComponents([.day], from: now, to: nextDate).day ?? -1
    }
    
    private func showToast(_ text: String) {
        withAnimation { toastText = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { toastText = nil } }
    }
}

// MARK: - Coupons Sheet
struct CouponsSheetView: View {
    let isAdmin: Bool
    let coupons: [LoveCoupon]
    let onRefresh: () async -> Void
    @Environment(\.dismiss) var dismiss
    @State private var redeemingId: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.meshBackground
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(coupons) { coupon in
                            HStack {
                                Text(coupon.emoji).font(.title)
                                VStack(alignment: .leading) {
                                    Text(coupon.title).font(.system(.body, design: .rounded, weight: .semibold)).strikethrough(coupon.redeemed)
                                    if !coupon.description.isEmpty { Text(coupon.description).font(.caption).foregroundStyle(.secondary) }
                                }
                                Spacer()
                                if coupon.redeemed {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.title2)
                                } else if !isAdmin {
                                    Button {
                                        Task {
                                            redeemingId = coupon.id
                                            try? await APIService.shared.redeemCoupon(id: coupon.id)
                                            await onRefresh()
                                            redeemingId = nil
                                        }
                                    } label: {
                                        Text("Canjear")
                                            .font(.system(.caption, design: .rounded, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 12).padding(.vertical, 6)
                                            .background(Capsule().fill(Theme.rosePrimary))
                                    }
                                    .disabled(redeemingId == coupon.id)
                                }
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                        }
                        if coupons.isEmpty {
                            Text("No hay cupones aún 🎟️").foregroundStyle(.secondary).padding(.top, 40)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Cupones de Amor 🎟️")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } } }
        }
    }
}

// MARK: - Achievements Sheet
struct AchievementsSheetView: View {
    let achievements: [Achievement]
    @Environment(\.dismiss) var dismiss
    
    private var categories: [String] { Array(Set(achievements.map { $0.category })).sorted() }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.meshBackground
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        let unlockedCount = achievements.filter { $0.unlocked }.count
                        Text("\(unlockedCount)/\(achievements.count) desbloqueados")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Theme.rosePrimary)
                            .frame(maxWidth: .infinity)
                        
                        ForEach(categories, id: \.self) { cat in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(cat.capitalized).font(.system(.subheadline, design: .rounded, weight: .bold)).foregroundStyle(.secondary)
                                
                                ForEach(achievements.filter { $0.category == cat }) { a in
                                    HStack {
                                        Text(a.emoji).font(.title2).opacity(a.unlocked ? 1 : 0.3).grayscale(a.unlocked ? 0 : 1)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(a.title).font(.system(.subheadline, design: .rounded, weight: .semibold)).foregroundStyle(a.unlocked ? .primary : .secondary)
                                            Text(a.description).font(.caption2).foregroundStyle(.tertiary)
                                        }
                                        Spacer()
                                        if a.unlocked {
                                            Image(systemName: "checkmark.seal.fill").foregroundStyle(.yellow).font(.title3)
                                        } else {
                                            Text("\(a.progress)/\(a.target)").font(.system(.caption2, design: .rounded, weight: .bold)).foregroundStyle(.tertiary)
                                        }
                                    }
                                    .padding(10)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(a.unlocked ? Theme.rosePrimary.opacity(0.05) : Color.gray.opacity(0.05)))
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Logros 🏆")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } } }
        }
    }
}
