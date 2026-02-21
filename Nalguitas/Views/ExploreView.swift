import SwiftUI
import PhotosUI

struct ExploreView: View {
    let isAdmin: Bool
    @State private var daysTogether: DaysTogether?
    @State private var todayQuestion: DailyQuestion?
    @State private var todayMood: MoodEntry?
    @State private var coupons: [LoveCoupon] = []
    @State private var achievements: [Achievement] = []
    @State private var songs: [Song] = []
    @State private var specialDates: [SpecialDate] = []
    @State private var plans: [DatePlan] = []
    @State private var photos: [SharedPhoto] = []
    @State private var moodHistory: [MoodEntry] = []
    @State private var answeredQuestions: [DailyQuestion] = []
    @State private var showMoodPicker = false
    @State private var showCoupons = false
    @State private var showAchievements = false
    @State private var showSongs = false
    @State private var questionAnswer = ""
    @State private var isAnswering = false
    @State private var moodNote = ""
    @State private var customFact: CustomFact?
    
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
    
    // Plan creation
    @State private var showPlanSheet = false
    @State private var planTitle = ""
    @State private var planDescription = ""
    @State private var planCategory = "cita"
    @State private var planDate = Date()
    @State private var planTime = Date()
    @State private var isCreatingPlan = false
    
    // Photo upload
    @State private var showPhotoSheet = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoCaption = ""
    @State private var isUploadingPhoto = false
    @State private var selectedImageData: Data?
    
    // Admin monitoring
    @State private var showMoodHistory = false
    @State private var showAnswerHistory = false
    
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
                        
                        // Love Challenge of the Day
                        loveChallengeCard
                        
                        // Mood Tracker
                        moodCard
                        
                        // Daily Question
                        if let question = todayQuestion, question.id != nil {
                            questionCard(question)
                        }
                        
                        // Romantic Fact
                        romanticFactCard
                        
                        // Quick Actions Grid
                        quickActionsGrid
                        
                        // Plans section
                        if !plans.isEmpty {
                            plansCard
                        }
                        
                        // Photo Gallery Preview
                        if !photos.isEmpty {
                            photoGalleryPreview
                        }
                        
                        // Upcoming Dates
                        if !specialDates.isEmpty {
                            upcomingDatesCard
                        }
                        
                        // Recent Songs
                        if !songs.isEmpty {
                            recentSongsCard
                        }
                        
                        // Admin: Mood History
                        if isAdmin && !moodHistory.isEmpty {
                            adminMoodHistoryCard
                        }
                        
                        // Admin: Question Answers
                        if isAdmin && !answeredQuestions.isEmpty {
                            adminAnswersCard
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
            .sheet(isPresented: $showPlanSheet) { planCreateSheet }
            .sheet(isPresented: $showPhotoSheet) { photoUploadSheet }
            .sheet(isPresented: $showMoodHistory) { moodHistorySheet }
            .sheet(isPresented: $showAnswerHistory) { answerHistorySheet }
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
                .contentTransition(.numericText())
            
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
    
    // MARK: - Love Challenge
    private var loveChallengeCard: some View {
        let challenge = LoveChallenge.todayChallenge()
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Reto de Amor del Día", systemImage: "flame.fill")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.orange)
                Spacer()
                Text(challenge.emoji).font(.title)
            }
            Text(challenge.challenge)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(Color(red: 0.30, green: 0.20, blue: 0.22))
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.orange.opacity(0.2), lineWidth: 1)).shadow(color: Color.orange.opacity(0.1), radius: 8, y: 3))
    }
    
    // MARK: - Mood Card
    private var moodCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("¿Cómo te sientes hoy?", systemImage: "heart.circle")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.rosePrimary)
                Spacer()
                if let mood = todayMood { Text(mood.emoji).font(.title) }
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
                            Button { Task { await selectMood(option) } } label: {
                                VStack(spacing: 2) {
                                    Text(option.emoji).font(.system(size: 28))
                                    Text(option.mood).font(.system(.caption2, design: .rounded)).foregroundStyle(.secondary)
                                }.frame(width: 60, height: 55)
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
                        .lineLimit(2...3).padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.6)))
                    Button { Task { await submitAnswer(q) } } label: {
                        Image(systemName: isAnswering ? "hourglass" : "arrow.up.circle.fill").font(.title2).foregroundStyle(Theme.rosePrimary)
                    }.disabled(questionAnswer.isEmpty || isAnswering)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).shadow(color: Theme.rosePrimary.opacity(0.1), radius: 8, y: 3))
    }
    
    // MARK: - Romantic Fact
    private var romanticFactCard: some View {
        let factText = customFact?.fact ?? RomanticFact.todayFact().fact
        return VStack(alignment: .leading, spacing: 8) {
            Label("¿Sabías que...?", systemImage: "lightbulb.fill")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(.purple)
            Text(factText)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Color(red: 0.30, green: 0.20, blue: 0.22))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.purple.opacity(0.15), lineWidth: 1)).shadow(color: Color.purple.opacity(0.05), radius: 4, y: 2))
    }
    
    // MARK: - Quick Actions
    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            quickAction(icon: "🎟️", title: "Cupones", count: coupons.filter { !$0.redeemed }.count) { showCoupons = true }
            quickAction(icon: "🏆", title: "Logros", count: achievements.filter { $0.unlocked }.count) { showAchievements = true }
            quickAction(icon: "🎵", title: "Canciones", count: songs.count) { showSongSheet = true }
            quickAction(icon: "📸", title: "Fotos", count: photos.count) { showPhotoSheet = true }
            quickAction(icon: "📍", title: "Planes", count: plans.filter { $0.status == "pendiente" }.count) { showPlanSheet = true }
            if isAdmin {
                quickAction(icon: "🎟️✨", title: "Crear Cupón", count: nil) { showCouponSheet = true }
            }
        }
    }
    
    private func quickAction(icon: String, title: String, count: Int?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(icon).font(.system(size: 24))
                Text(title).font(.system(.caption2, design: .rounded, weight: .semibold)).foregroundStyle(Color(red: 0.30, green: 0.20, blue: 0.22))
                if let count = count { Text("\(count)").font(.system(.caption2, design: .rounded, weight: .bold)).foregroundStyle(Theme.rosePrimary) }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial).shadow(color: Theme.rosePrimary.opacity(0.05), radius: 4, y: 2))
        }
    }
    
    // MARK: - Plans Card
    private var plansCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Planes de Pareja", systemImage: "map.fill")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.rosePrimary)
                Spacer()
                Button { showPlanSheet = true } label: {
                    Image(systemName: "plus.circle.fill").font(.title3).foregroundStyle(Theme.rosePrimary)
                }
            }
            ForEach(plans.filter { $0.status != "cancelado" }.prefix(3)) { plan in
                HStack {
                    Text(PlanCategory.categories.first { $0.id == plan.category }?.emoji ?? "💕").font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(plan.title).font(.system(.subheadline, design: .rounded, weight: .semibold))
                        HStack(spacing: 4) {
                            if !plan.proposedDate.isEmpty { Text(plan.proposedDate).font(.caption2).foregroundStyle(.secondary) }
                            if !plan.proposedTime.isEmpty { Text("• \(plan.proposedTime)").font(.caption2).foregroundStyle(.secondary) }
                        }
                    }
                    Spacer()
                    Text(plan.statusEmoji).font(.title3)
                    if plan.status == "pendiente" {
                        Button {
                            Task {
                                try? await APIService.shared.updatePlanStatus(id: plan.id, status: "aceptado")
                                await loadData()
                            }
                        } label: {
                            Text("Aceptar").font(.system(.caption2, design: .rounded, weight: .bold)).foregroundStyle(.white).padding(.horizontal, 8).padding(.vertical, 4).background(Capsule().fill(.green))
                        }
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).shadow(color: Theme.rosePrimary.opacity(0.1), radius: 8, y: 3))
    }
    
    // MARK: - Photo Gallery Preview
    private var photoGalleryPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Galería de Fotos", systemImage: "photo.on.rectangle.angled")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.rosePrimary)
                Spacer()
                Button { showPhotoSheet = true } label: {
                    Image(systemName: "plus.circle.fill").font(.title3).foregroundStyle(Theme.rosePrimary)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(photos.prefix(6)) { photo in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(colors: [Theme.rosePrimary.opacity(0.2), Theme.roseQuartz.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 90, height: 90)
                                .overlay(Image(systemName: "photo.fill").font(.title2).foregroundStyle(Theme.rosePrimary.opacity(0.5)))
                            if !photo.caption.isEmpty { Text(photo.caption).font(.caption2).foregroundStyle(.secondary).lineLimit(1).frame(width: 90) }
                        }
                    }
                }
            }
            Text("\(photos.count) fotos compartidas").font(.caption).foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).shadow(color: Theme.rosePrimary.opacity(0.1), radius: 8, y: 3))
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
                    if daysUntil >= 0 { Text("en \(daysUntil) días").font(.system(.caption, design: .rounded, weight: .bold)).foregroundStyle(Theme.rosePrimary) }
                    else { Text("pasó").font(.caption).foregroundStyle(.tertiary) }
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
                    if let url = URL(string: s.youtubeUrl) { UIApplication.shared.open(url) }
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
    
    // MARK: - Admin: Mood History
    private var adminMoodHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Su Historial de Moods", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.indigo)
                Spacer()
                Button("Ver todo") { showMoodHistory = true }.font(.caption).foregroundStyle(Theme.rosePrimary)
            }
            HStack(spacing: 6) {
                ForEach(moodHistory.prefix(7)) { mood in
                    VStack(spacing: 2) {
                        Text(mood.emoji).font(.title3)
                        Text(shortDate(mood.createdAt)).font(.system(size: 8)).foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.indigo.opacity(0.15), lineWidth: 1)).shadow(color: Color.indigo.opacity(0.08), radius: 6, y: 3))
    }
    
    // MARK: - Admin: Answers
    private var adminAnswersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Sus Respuestas", systemImage: "text.bubble.fill")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.teal)
                Spacer()
                Button("Ver todo") { showAnswerHistory = true }.font(.caption).foregroundStyle(Theme.rosePrimary)
            }
            ForEach(answeredQuestions.prefix(2)) { q in
                VStack(alignment: .leading, spacing: 4) {
                    Text(q.question).font(.system(.caption, design: .rounded, weight: .medium)).foregroundStyle(.secondary)
                    Text(q.answer ?? "").font(.system(.subheadline, design: .rounded)).foregroundStyle(.primary)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.teal.opacity(0.05)))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.teal.opacity(0.15), lineWidth: 1)).shadow(color: Color.teal.opacity(0.08), radius: 6, y: 3))
    }
    
    // MARK: - Song Share Sheet
    private var songShareSheet: some View {
        NavigationStack {
            ZStack {
                Theme.meshBackground
                ScrollView {
                    VStack(spacing: 16) {
                        // Show existing songs first
                        if !songs.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Canciones compartidas (\(songs.count))").font(.system(.subheadline, design: .rounded, weight: .bold)).foregroundStyle(.secondary)
                                ForEach(songs) { s in
                                    Button { if let url = URL(string: s.youtubeUrl) { UIApplication.shared.open(url) } } label: {
                                        HStack {
                                            Image(systemName: "play.circle.fill").foregroundStyle(.red)
                                            VStack(alignment: .leading) {
                                                Text(s.title.isEmpty ? "🎵" : s.title).font(.subheadline).foregroundStyle(.primary)
                                                if !s.artist.isEmpty { Text(s.artist).font(.caption2).foregroundStyle(.secondary) }
                                            }
                                            Spacer()
                                            if !s.message.isEmpty { Text(s.message).font(.caption2).foregroundStyle(.tertiary).lineLimit(1) }
                                        }.padding(8).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
                                    }
                                }
                            }
                            Divider().padding(.vertical, 8)
                        }
                        
                        Text("Compartir nueva canción").font(.system(.headline, design: .rounded, weight: .bold)).foregroundStyle(Theme.rosePrimary)
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
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [Theme.rosePrimary, Theme.roseQuartz], startPoint: .leading, endPoint: .trailing)))
                        }.disabled(songUrl.isEmpty || isSendingSong)
                    }.padding(20)
                }
            }
            .navigationTitle("Canciones 🎵")
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
                        }.font(.system(.body, design: .rounded, weight: .semibold)).foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 14).background(RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [Theme.rosePrimary, Theme.roseQuartz], startPoint: .leading, endPoint: .trailing)))
                    }.disabled(couponTitle.isEmpty || isCreatingCoupon)
                    Spacer()
                }.padding(20)
            }
            .navigationTitle("Crear Cupón de Amor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { showCouponSheet = false } } }
        }
    }
    
    // MARK: - Plan Create Sheet
    private var planCreateSheet: some View {
        NavigationStack {
            ZStack {
                Theme.meshBackground
                ScrollView {
                    VStack(spacing: 16) {
                        // Existing plans
                        if !plans.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Planes existentes").font(.system(.subheadline, design: .rounded, weight: .bold)).foregroundStyle(.secondary)
                                ForEach(plans) { plan in
                                    HStack {
                                        Text(PlanCategory.categories.first { $0.id == plan.category }?.emoji ?? "💕")
                                        VStack(alignment: .leading) {
                                            Text(plan.title).font(.subheadline).strikethrough(plan.status == "completado")
                                            HStack(spacing: 4) {
                                                if !plan.proposedDate.isEmpty { Text(plan.proposedDate).font(.caption2).foregroundStyle(.secondary) }
                                                Text("• \(plan.proposedBy == "admin" ? "Isacc" : "Tú")").font(.caption2).foregroundStyle(.tertiary)
                                            }
                                        }
                                        Spacer()
                                        Text(plan.statusEmoji)
                                    }.padding(8).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
                                }
                            }
                            Divider().padding(.vertical, 8)
                        }
                        
                        Text("Proponer nuevo plan").font(.system(.headline, design: .rounded, weight: .bold)).foregroundStyle(Theme.rosePrimary)
                        
                        // Category picker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(PlanCategory.categories) { cat in
                                    Button { planCategory = cat.id } label: {
                                        VStack(spacing: 2) {
                                            Text(cat.emoji).font(.title2)
                                            Text(cat.name).font(.system(.caption2, design: .rounded)).foregroundStyle(planCategory == cat.id ? Theme.rosePrimary : .secondary)
                                        }
                                        .padding(8)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(planCategory == cat.id ? Theme.rosePrimary.opacity(0.1) : Color.clear))
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(planCategory == cat.id ? Theme.rosePrimary : Color.clear, lineWidth: 1))
                                    }
                                }
                            }
                        }
                        
                        TextField("¿Qué plan propones?", text: $planTitle).textFieldStyle(.roundedBorder)
                        TextField("Descripción (opcional)", text: $planDescription).textFieldStyle(.roundedBorder)
                        DatePicker("Fecha", selection: $planDate, displayedComponents: .date).tint(Theme.rosePrimary)
                        DatePicker("Hora", selection: $planTime, displayedComponents: .hourAndMinute).tint(Theme.rosePrimary)
                        
                        Button { Task { await createPlan() } } label: {
                            HStack {
                                if isCreatingPlan { ProgressView().tint(.white) } else { Image(systemName: "map.fill"); Text("Proponer Plan") }
                            }.font(.system(.body, design: .rounded, weight: .semibold)).foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 14).background(RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [Theme.rosePrimary, Theme.roseQuartz], startPoint: .leading, endPoint: .trailing)))
                        }.disabled(planTitle.isEmpty || isCreatingPlan)
                    }.padding(20)
                }
            }
            .navigationTitle("Planes de Pareja 📍")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { showPlanSheet = false } } }
        }
    }
    
    // MARK: - Photo Upload Sheet
    private var photoUploadSheet: some View {
        NavigationStack {
            ZStack {
                Theme.meshBackground
                ScrollView {
                    VStack(spacing: 16) {
                        // Existing photos grid
                        if !photos.isEmpty {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(photos) { photo in
                                    VStack(spacing: 2) {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(LinearGradient(colors: [Theme.rosePrimary.opacity(0.15), Theme.roseQuartz.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(height: 80)
                                            .overlay(Image(systemName: "photo.fill").foregroundStyle(Theme.rosePrimary.opacity(0.4)))
                                        if !photo.caption.isEmpty { Text(photo.caption).font(.system(size: 9)).foregroundStyle(.secondary).lineLimit(1) }
                                        Text(photo.uploadedBy == "admin" ? "Isacc" : "Tú").font(.system(size: 8, weight: .medium, design: .rounded)).foregroundStyle(.tertiary)
                                    }
                                }
                            }
                            Divider().padding(.vertical, 8)
                        }
                        
                        Text("Subir nueva foto").font(.system(.headline, design: .rounded, weight: .bold)).foregroundStyle(Theme.rosePrimary)
                        
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            HStack {
                                Image(systemName: "photo.badge.plus")
                                Text("Seleccionar foto")
                            }
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(Theme.rosePrimary)
                            .frame(maxWidth: .infinity).padding(.vertical, 40)
                            .background(RoundedRectangle(cornerRadius: 16).strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8])).foregroundStyle(Theme.rosePrimary.opacity(0.3)))
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                }
                            }
                        }
                        
                        if selectedImageData != nil {
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                Text("Foto seleccionada").font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        
                        TextField("Descripción de la foto", text: $photoCaption).textFieldStyle(.roundedBorder)
                        
                        Button { Task { await uploadPhoto() } } label: {
                            HStack {
                                if isUploadingPhoto { ProgressView().tint(.white) } else { Image(systemName: "arrow.up.circle.fill"); Text("Subir Foto") }
                            }.font(.system(.body, design: .rounded, weight: .semibold)).foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 14).background(RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [Theme.rosePrimary, Theme.roseQuartz], startPoint: .leading, endPoint: .trailing)))
                        }.disabled(selectedImageData == nil || isUploadingPhoto)
                    }.padding(20)
                }
            }
            .navigationTitle("Galería de Fotos 📸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { showPhotoSheet = false } } }
        }
    }
    
    // MARK: - Mood History Sheet
    private var moodHistorySheet: some View {
        NavigationStack {
            ZStack {
                Theme.meshBackground
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(moodHistory) { m in
                            HStack {
                                Text(m.emoji).font(.title2)
                                VStack(alignment: .leading) {
                                    Text(m.mood).font(.system(.subheadline, design: .rounded, weight: .semibold))
                                    if let note = m.note, !note.isEmpty { Text(note).font(.caption).foregroundStyle(.secondary) }
                                }
                                Spacer()
                                Text(shortDate(m.createdAt)).font(.caption2).foregroundStyle(.tertiary)
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                        }
                    }.padding(20)
                }
            }
            .navigationTitle("Historial de Moods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { showMoodHistory = false } } }
        }
    }
    
    // MARK: - Answer History Sheet
    private var answerHistorySheet: some View {
        NavigationStack {
            ZStack {
                Theme.meshBackground
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(answeredQuestions) { q in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(q.category ?? "").font(.caption2).foregroundStyle(.white).padding(.horizontal, 6).padding(.vertical, 2).background(Capsule().fill(Theme.rosePrimary))
                                    Spacer()
                                    Text(shortDate(q.answeredAt)).font(.caption2).foregroundStyle(.tertiary)
                                }
                                Text(q.question).font(.system(.subheadline, design: .rounded, weight: .medium)).foregroundStyle(.secondary)
                                Text(q.answer ?? "").font(.system(.body, design: .rounded)).foregroundStyle(.primary)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                        }
                    }.padding(20)
                }
            }
            .navigationTitle("Sus Respuestas 📝")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { showAnswerHistory = false } } }
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
        async let p = try? APIService.shared.fetchPlans()
        async let ph = try? APIService.shared.fetchPhotos()
        async let mh = try? APIService.shared.fetchMoods()
        async let aq = try? APIService.shared.fetchAnsweredQuestions()
        
        let (days, question, mood, cps, achs, sgs, dts, pls, phs, moods, answered) = await (d, q, m, c, a, s, dates, p, ph, mh, aq)
        daysTogether = days
        todayQuestion = question
        todayMood = mood
        coupons = cps ?? []
        achievements = achs ?? []
        songs = sgs ?? []
        specialDates = dts ?? []
        plans = pls ?? []
        photos = phs ?? []
        moodHistory = moods ?? []
        answeredQuestions = answered ?? []
        customFact = try? await APIService.shared.fetchRandomFact()
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
        isAnswering = true; defer { isAnswering = false }
        do {
            try await APIService.shared.answerQuestion(id: id, answer: questionAnswer)
            todayQuestion = DailyQuestion(id: id, question: q.question, category: q.category, answered: true, answer: questionAnswer, answeredAt: nil, shownDate: nil)
            questionAnswer = ""
            showToast("¡Respuesta enviada! 💕")
        } catch {}
    }
    
    private func shareSong() async {
        isSendingSong = true; defer { isSendingSong = false }
        do {
            try await APIService.shared.sendSong(youtubeUrl: songUrl, title: songTitle, artist: songArtist, message: songMessage, fromGirlfriend: !isAdmin)
            showSongSheet = false; songUrl = ""; songTitle = ""; songArtist = ""; songMessage = ""
            showToast("¡Canción compartida! 🎵"); await loadData()
        } catch {}
    }
    
    private func createCoupon() async {
        isCreatingCoupon = true; defer { isCreatingCoupon = false }
        do {
            try await APIService.shared.createCoupon(title: couponTitle, description: couponDescription, emoji: couponEmoji)
            showCouponSheet = false; couponTitle = ""; couponDescription = ""
            showToast("¡Cupón creado! 🎟️"); await loadData()
        } catch {}
    }
    
    private func createPlan() async {
        isCreatingPlan = true; defer { isCreatingPlan = false }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        do {
            try await APIService.shared.createPlan(title: planTitle, description: planDescription, category: planCategory, date: dateFormatter.string(from: planDate), time: timeFormatter.string(from: planTime), proposedBy: isAdmin ? "admin" : "girlfriend")
            showPlanSheet = false; planTitle = ""; planDescription = ""
            showToast("¡Plan propuesto! 📍"); await loadData()
        } catch {}
    }
    
    private func uploadPhoto() async {
        guard let data = selectedImageData else { return }
        isUploadingPhoto = true; defer { isUploadingPhoto = false }
        // Compress with JPEG at 0.3 quality
        let uiImage = UIImage(data: data)
        guard let compressed = uiImage?.jpegData(compressionQuality: 0.3) else { return }
        let base64 = compressed.base64EncodedString()
        do {
            try await APIService.shared.uploadPhoto(imageData: base64, caption: photoCaption, uploadedBy: isAdmin ? "admin" : "girlfriend")
            showPhotoSheet = false; selectedImageData = nil; photoCaption = ""; selectedPhotoItem = nil
            showToast("¡Foto compartida! 📸"); await loadData()
        } catch {}
    }
    
    private func daysUntilDate(_ dateStr: String) -> Int {
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return -1 }
        var nextDate = date; let now = Date()
        while nextDate < now { nextDate = Calendar.current.date(byAdding: .year, value: 1, to: nextDate) ?? nextDate }
        return Calendar.current.dateComponents([.day], from: now, to: nextDate).day ?? -1
    }
    
    private func shortDate(_ dateStr: String?) -> String {
        guard let str = dateStr else { return "" }
        let iso = ISO8601DateFormatter(); iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = iso.date(from: str) ?? ISO8601DateFormatter().date(from: str) else { return String(str.prefix(10)) }
        let df = DateFormatter(); df.dateFormat = "dd/MM"
        return df.string(from: date)
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
                                        Task { redeemingId = coupon.id; try? await APIService.shared.redeemCoupon(id: coupon.id); await onRefresh(); redeemingId = nil }
                                    } label: {
                                        Text("Canjear").font(.system(.caption, design: .rounded, weight: .bold)).foregroundStyle(.white).padding(.horizontal, 12).padding(.vertical, 6).background(Capsule().fill(Theme.rosePrimary))
                                    }.disabled(redeemingId == coupon.id)
                                }
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                        }
                        if coupons.isEmpty { Text("No hay cupones aún 🎟️").foregroundStyle(.secondary).padding(.top, 40) }
                    }.padding(20)
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
                        Text("\(unlockedCount)/\(achievements.count) desbloqueados").font(.system(.headline, design: .rounded)).foregroundStyle(Theme.rosePrimary).frame(maxWidth: .infinity)
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
                                        if a.unlocked { Image(systemName: "checkmark.seal.fill").foregroundStyle(.yellow).font(.title3) }
                                        else { Text("\(a.progress)/\(a.target)").font(.system(.caption2, design: .rounded, weight: .bold)).foregroundStyle(.tertiary) }
                                    }
                                    .padding(10)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(a.unlocked ? Theme.rosePrimary.opacity(0.05) : Color.gray.opacity(0.05)))
                                }
                            }
                        }
                    }.padding(20)
                }
            }
            .navigationTitle("Logros 🏆")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } } }
        }
    }
}
