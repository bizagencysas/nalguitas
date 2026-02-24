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
    @State private var showGallery = false
    @State private var showWishList = false
    
    // New features state
    @State private var todayWord: EnglishWord?
    @State private var aiWordExample: String?
    @State private var scratchCard: ScratchCard?
    @State private var scratchPoints: [CGPoint] = []
    @State private var scratchPercentage: Double = 0
    @State private var showScratchSheet = false
    @State private var isScratched = false
    @State private var rouletteOptions: [RouletteOption] = []
    @State private var showRouletteSheet = false
    @State private var rouletteResult: String?
    @State private var isSpinning = false
    @State private var newRouletteOption = ""
    @State private var showDiarySheet = false
    @State private var diaryText: String = ""
    @State private var partnerDiary: [DiaryEntry] = []
    @State private var pointsBalance: Int = 0
    @State private var rewards: [Reward] = []
    @State private var showRewardsSheet = false
    @State private var showExperiencesSheet = false
    @State private var experiences: [Experience] = []
    
    @State private var toastText: String?
    @State private var fullScreenPhoto: UIImage?
    
    @Namespace private var exploreAnimation
    @StateObject private var confettiManager = ConfettiManager()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.meshBackground
                
                ScrollView {
                    topSection
                    middleSection
                    newFeaturesSection
                    adminSection
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
            .overlay {
                if let image = fullScreenPhoto {
                    ZStack {
                        Color.black.ignoresSafeArea()
                            .onTapGesture { withAnimation { fullScreenPhoto = nil } }
                        
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .ignoresSafeArea()
                            .parallaxMotion(magnitude: 35)
                        
                        VStack {
                            HStack {
                                Spacer()
                                Button {
                                    withAnimation { fullScreenPhoto = nil }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundStyle(.white.opacity(0.8))
                                        .padding(16)
                                }
                            }
                            Spacer()
                            HStack {
                                Spacer()
                                Button {
                                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                                    withAnimation { fullScreenPhoto = nil }
                                } label: {
                                    Label("Guardar", systemImage: "square.and.arrow.down")
                                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(Capsule().fill(.ultraThinMaterial))
                                }
                                .padding(20)
                            }
                        }
                    }
                    .transition(.opacity)
                    .zIndex(100)
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
            .sheet(isPresented: $showGallery) { fullGallerySheet }
            .sheet(isPresented: $showScratchSheet) { scratchCardSheet }
            .sheet(isPresented: $showRouletteSheet) { rouletteSheet }
            .sheet(isPresented: $showDiarySheet) { diarySheet }
            .sheet(isPresented: $showRewardsSheet) { rewardsSheet }
            .sheet(isPresented: $showExperiencesSheet) { experiencesSheet }
            .sheet(isPresented: $showWishList) { WishListView(isAdmin: UserDefaults.standard.bool(forKey: "isAdminDevice")) }
            .task { await loadData() }
            .refreshable { await loadData() }
            
            if showScratchSheet {
                scratchCardSheet
                    .matchedGeometryEffect(id: "scratchGeo", in: exploreAnimation)
                    .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .scale(scale: 0.95).combined(with: .opacity)))
                    .zIndex(200)
            }
            if showDiarySheet {
                diarySheet
                    .matchedGeometryEffect(id: "diaryGeo", in: exploreAnimation)
                    .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .scale(scale: 0.95).combined(with: .opacity)))
                    .zIndex(200)
            }
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
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(LinearGradient(colors: [.white.opacity(0.6), Theme.roseLight.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.5)).shadow(color: Theme.rosePrimary.opacity(0.08), radius: 8, y: 3))
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
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(LinearGradient(colors: [.white.opacity(0.6), Theme.roseLight.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.5)).shadow(color: Theme.rosePrimary.opacity(0.05), radius: 4, y: 2))
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
        VStack(spacing: 12) {
            HStack {
                Text("Planes Propuestos").font(.system(.headline, design: .rounded, weight: .bold)).foregroundStyle(Theme.textPrimary)
                Spacer()
                if isAdmin {
                    Button(action: { showPlanSheet = true }) {
                        Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(Theme.rosePrimary)
                    }
                }
            }
            // Render the Tinder-style Swipe Cards instead of a boring list!
            DatePlanSwipeView(plans: $plans, isAdmin: isAdmin) {
                Task { await loadData() }
            }
        }
        .padding(20)
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
                            if let imgData = photo.imageData, !imgData.isEmpty,
                               let data = Data(base64Encoded: imgData),
                               let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 90, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .onTapGesture { fullScreenPhoto = uiImage }
                                    .contextMenu {
                                        Button {
                                            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        } label: { Label("Guardar en Fotos", systemImage: "square.and.arrow.down") }
                                    } preview: {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    }
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(colors: [Theme.rosePrimary.opacity(0.2), Theme.roseQuartz.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 90, height: 90)
                                    .overlay(Image(systemName: "photo.fill").font(.title2).foregroundStyle(Theme.rosePrimary.opacity(0.5)))
                            }
                            if !photo.caption.isEmpty { Text(photo.caption).font(.caption2).foregroundStyle(.secondary).lineLimit(1).frame(width: 90) }
                        }
                        .scrollTransition(.animated.threshold(.visible(0.3))) { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1 : 0.6)
                                .scaleEffect(phase.isIdentity ? 1 : 0.85)
                                .blur(radius: phase.isIdentity ? 0 : 2)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, -16)
            Button { showGallery = true } label: {
                Text("Ver todas (\(photos.count) fotos) →").font(.system(.caption, design: .rounded, weight: .semibold)).foregroundStyle(Theme.rosePrimary)
            }
            
            // Wish List shortcut
            Button { showWishList = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Theme.accentGradient))
                    Text("Lista de Deseos 💝")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    LinearGradient(colors: [.white.opacity(0.6), Theme.roseLight.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 0.5
                                )
                        )
                )
            }
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
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(LinearGradient(colors: [.white.opacity(0.6), Theme.roseLight.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.5)).shadow(color: Theme.rosePrimary.opacity(0.06), radius: 6, y: 3))
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
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(LinearGradient(colors: [.white.opacity(0.6), Theme.roseLight.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.5)).shadow(color: Theme.rosePrimary.opacity(0.06), radius: 6, y: 3))
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
                        // Existing photos grid with actual images
                        if !photos.isEmpty {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(photos) { photo in
                                    VStack(spacing: 2) {
                                        if let imgData = photo.imageData, !imgData.isEmpty,
                                           let data = Data(base64Encoded: imgData),
                                           let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        } else {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(LinearGradient(colors: [Theme.rosePrimary.opacity(0.15), Theme.roseQuartz.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .frame(height: 80)
                                                .overlay(Image(systemName: "photo.fill").foregroundStyle(Theme.rosePrimary.opacity(0.4)))
                                        }
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
                        
                        // Show preview of selected photo
                        if let imgData = selectedImageData, let uiImage = UIImage(data: imgData) {
                            VStack(spacing: 6) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                HStack {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                    Text("Foto seleccionada").font(.subheadline).foregroundStyle(.secondary)
                                }
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
    
    // MARK: - Full Gallery Sheet
    private var fullGallerySheet: some View {
        NavigationStack {
            ZStack {
                Theme.meshBackground
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(photos) { photo in
                            VStack(spacing: 4) {
                                if let imgData = photo.imageData, !imgData.isEmpty,
                                   let data = Data(base64Encoded: imgData),
                                   let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(minHeight: 140, maxHeight: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .onTapGesture { fullScreenPhoto = uiImage }
                                        .contextMenu {
                                            Button {
                                                UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            } label: { Label("Guardar en Fotos", systemImage: "square.and.arrow.down") }
                                        } preview: {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                        }
                                } else {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(LinearGradient(colors: [Theme.rosePrimary.opacity(0.15), Theme.roseQuartz.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(height: 140)
                                        .overlay(Image(systemName: "photo.fill").font(.title).foregroundStyle(Theme.rosePrimary.opacity(0.4)))
                                }
                                if !photo.caption.isEmpty {
                                    Text(photo.caption)
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                Text(photo.uploadedBy == "admin" ? "📸 Isacc" : "📸 Tú")
                                    .font(.system(size: 9, weight: .medium, design: .rounded))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Todas las Fotos (\(photos.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { showGallery = false } }
                ToolbarItem(placement: .confirmationAction) { Button { showPhotoSheet = true } label: { Image(systemName: "plus.circle.fill").foregroundStyle(Theme.rosePrimary) } }
            }
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
    
    // MARK: - Offline Cache Struct
    private struct ExploreCache: Codable {
        let daysTogether: DaysTogether?
        let todayQuestion: DailyQuestion?
        let todayMood: MoodEntry?
        let coupons: [LoveCoupon]
        let achievements: [Achievement]
        let songs: [Song]
        let specialDates: [SpecialDate]
        let plans: [DatePlan]
        let photos: [SharedPhoto]
        let moodHistory: [MoodEntry]
        let answeredQuestions: [DailyQuestion]
        let customFact: CustomFact?
        let todayWord: EnglishWord?
        let scratchCard: ScratchCard?
        let rouletteOptions: [RouletteOption]
        let pointsBalance: Int
        let rewards: [Reward]
        let experiences: [Experience]
        let partnerDiary: [DiaryEntry]
    }
    
    // MARK: - Actions
    private func loadData() async {
        // Fast path: Load from cache instantly
        if let cachedData = UserDefaults.standard.data(forKey: "ExploreCache"),
           let cache = try? JSONDecoder().decode(ExploreCache.self, from: cachedData) {
            self.daysTogether = cache.daysTogether
            self.todayQuestion = cache.todayQuestion
            self.todayMood = cache.todayMood
            self.coupons = cache.coupons
            self.achievements = cache.achievements
            self.songs = cache.songs
            self.specialDates = cache.specialDates
            self.plans = cache.plans
            self.photos = cache.photos
            self.moodHistory = cache.moodHistory
            self.answeredQuestions = cache.answeredQuestions
            self.customFact = cache.customFact
            self.todayWord = cache.todayWord
            self.scratchCard = cache.scratchCard
            self.rouletteOptions = cache.rouletteOptions
            self.pointsBalance = cache.pointsBalance
            self.rewards = cache.rewards
            self.experiences = cache.experiences
            self.partnerDiary = cache.partnerDiary
        }
        
        
        // Launch network requests in a detached task to avoid blocking the initial cache render
        Task {
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
            
            async let fetchedFactPromise = try? APIService.shared.fetchRandomFact()
            async let fetchedWordPromise = try? APIService.shared.fetchTodayWord()
            async let fetchedScratchPromise = try? APIService.shared.fetchAvailableScratchCard()
            async let fetchedOptionsPromise = try? APIService.shared.fetchRouletteOptions(category: "general")
            async let ptsResultPromise = try? APIService.shared.fetchPoints(username: "girlfriend")
            async let fetchedRewardsPromise = try? APIService.shared.fetchRewards()
            async let fetchedExperiencesPromise = try? APIService.shared.fetchExperiences()
            async let fetchedDiaryPromise = try? APIService.shared.fetchPartnerDiary(author: isAdmin ? "admin" : "girlfriend")
            
            let (days, question, mood, cps, achs, sgs, dts, pls, phs, moods, answered) = await (d, q, m, c, a, s, dates, p, ph, mh, aq)
            
            // Await the new async let promises concurrently
            let fetchedFact = await fetchedFactPromise
            let fetchedWord = await fetchedWordPromise
            let fetchedScratch = await fetchedScratchPromise
            let fetchedOptions = await fetchedOptionsPromise ?? []
            let ptsResult = await ptsResultPromise
            let fetchedBalance = ptsResult?.balance ?? 0
            let fetchedRewards = await fetchedRewardsPromise ?? []
            let fetchedExperiences = await fetchedExperiencesPromise ?? []
            let fetchedDiary = await fetchedDiaryPromise ?? []
            
            // Update state on MainActor implicitly via await
            self.daysTogether = days
            self.todayQuestion = question
            self.todayMood = mood
            self.coupons = cps ?? []
            self.achievements = achs ?? []
            self.songs = sgs ?? []
            self.specialDates = dts ?? []
            self.plans = pls ?? []
            self.photos = phs ?? []
            self.moodHistory = moods ?? []
            self.answeredQuestions = answered ?? []
            self.customFact = fetchedFact
            self.todayWord = fetchedWord
            self.scratchCard = fetchedScratch
            self.rouletteOptions = fetchedOptions
            self.pointsBalance = fetchedBalance
            self.rewards = fetchedRewards
            self.experiences = fetchedExperiences
            self.partnerDiary = fetchedDiary
            
            // Save to cache
            let newCache = ExploreCache(daysTogether: self.daysTogether, todayQuestion: self.todayQuestion, todayMood: self.todayMood, coupons: self.coupons, achievements: self.achievements, songs: self.songs, specialDates: self.specialDates, plans: self.plans, photos: self.photos, moodHistory: self.moodHistory, answeredQuestions: self.answeredQuestions, customFact: self.customFact, todayWord: self.todayWord, scratchCard: self.scratchCard, rouletteOptions: self.rouletteOptions, pointsBalance: self.pointsBalance, rewards: self.rewards, experiences: self.experiences, partnerDiary: self.partnerDiary)
            if let encoded = try? JSONEncoder().encode(newCache) {
                UserDefaults.standard.set(encoded, forKey: "ExploreCache")
            }
        }
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
            await PointsService.shared.awardPoint(reason: "Respondió pregunta ❓")
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
    
    // MARK: - Body Sections (split for compiler performance)
    @ViewBuilder
    private var topSection: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 10)
            if let days = daysTogether { daysCounterCard(days) }
            loveChallengeCard
            moodCard
            if let question = todayQuestion, question.id != nil { questionCard(question) }
            romanticFactCard
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var middleSection: some View {
        VStack(spacing: 20) {
            quickActionsGrid
            throwbackMemoryCard
            if !plans.isEmpty { plansCard }
            if !photos.isEmpty { photoGalleryPreview }
            if !specialDates.isEmpty { upcomingDatesCard }
            if !songs.isEmpty { recentSongsCard }
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var adminSection: some View {
        VStack(spacing: 20) {
            if isAdmin && !moodHistory.isEmpty { adminMoodHistoryCard }
            if isAdmin && !answeredQuestions.isEmpty { adminAnswersCard }
            Spacer(minLength: 60)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - New Features Section (split to help compiler)
    @ViewBuilder
    private var newFeaturesSection: some View {
        VStack(spacing: 20) {
            // Palabra del Día
            if let word = todayWord {
                wordOfDayCard(word)
            }
            
            // Raspa y Gana
            if scratchCard != nil {
                scratchCardPreview
            }
            
            // Ruleta de Decisiones
            roulettePreviewCard
            
            // Diario Compartido
            diaryPreviewCard
            
            // Puntos y Recompensas
            pointsPreviewCard
            
            // Lista de Experiencias
            if !experiences.isEmpty {
                experiencesPreviewCard
            }
        }
        .padding(.horizontal, 20)
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
                                        Task { redeemingId = coupon.id; try? await APIService.shared.redeemCoupon(id: coupon.id); await PointsService.shared.awardPoint(reason: "Canjeó cupón 🎟️"); AmbientAudio.shared.playApplePaySuccess(); await onRefresh(); redeemingId = nil }
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

// MARK: - New Feature Views
extension ExploreView {
    // MARK: - Word of the Day Card
    private func wordOfDayCard(_ word: EnglishWord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Palabra del Día 🇺🇸", systemImage: "textformat.abc")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.rosePrimary)
                Spacer()
                Text("Day \(word.dayOfYear)")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(word.word)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text(word.translation)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text("/\(word.pronunciation)/")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Text("📚").font(.system(size: 44))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("🇺🇸 \(word.exampleEn)").font(.system(.caption, design: .rounded)).foregroundStyle(.primary)
                Text("🇪🇸 \(word.exampleEs)").font(.system(.caption, design: .rounded)).foregroundStyle(.secondary)
            }
            if let ai = aiWordExample ?? word.aiExample, !ai.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Label("Rork AI dice:", systemImage: "sparkles")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundStyle(.purple)
                    Text(ai).font(.system(.caption, design: .rounded)).foregroundStyle(.primary)
                }
            }
            Button {
                Task {
                    aiWordExample = try? await APIService.shared.fetchAiExample(word: word.word, translation: word.translation, dayOfYear: word.dayOfYear)
                }
            } label: {
                Label("Generar ejemplo con IA", systemImage: "sparkles")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(LinearGradient(colors: [.purple, Theme.rosePrimary], startPoint: .leading, endPoint: .trailing)))
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).shadow(color: Theme.rosePrimary.opacity(0.1), radius: 8, y: 4))
    }
    
    // MARK: - Scratch Card Preview
    private var scratchCardPreview: some View {
        Button { withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showScratchSheet = true } } label: {
            HStack {
                Text("🎟").font(.system(size: 36))
                VStack(alignment: .leading, spacing: 4) {
                    Text("¡Raspa y Gana Disponible!")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.rosePrimary)
                    Text("Tienes un cupón sorpresa esperando")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "hand.draw.fill").font(.title2).foregroundStyle(.orange).symbolEffect(.pulse)
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.ultraThinMaterial).shadow(color: Theme.rosePrimary.opacity(0.1), radius: 8, y: 4))
            .matchedGeometryEffect(id: "scratchGeo", in: exploreAnimation)
        }
    }
    
    // MARK: - Scratch Card Sheet

    
    private var scratchCardSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("🎰 Raspa y Gana").font(.system(.title2, design: .rounded, weight: .bold)).foregroundStyle(Theme.rosePrimary)
                
                // Scratch card area
                ZStack {
                    // Prize layer (hidden underneath)
                    VStack(spacing: 16) {
                        Text(scratchCard?.emoji ?? "🎁").font(.system(size: 60))
                        Text("🎉 ¡Ganaste!").font(.system(.title2, design: .rounded, weight: .bold)).foregroundStyle(Theme.rosePrimary)
                        Text(scratchCard?.prize ?? "").font(.system(.title3, design: .rounded, weight: .semibold)).foregroundStyle(.primary).multilineTextAlignment(.center).padding(.horizontal, 16)
                    }
                    .frame(width: 280, height: 280)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.97, blue: 0.95), Color(red: 1.0, green: 0.93, blue: 0.93)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                    
                    // Scratch overlay (golden layer)
                    if !isScratched {
                        Canvas { context, size in
                            // Draw golden background
                            let rect = CGRect(origin: .zero, size: size)
                            context.fill(Path(roundedRect: rect, cornerRadius: 24), with: .linearGradient(
                                Gradient(colors: [Color(red: 0.85, green: 0.65, blue: 0.13), Color(red: 0.93, green: 0.79, blue: 0.28), Color(red: 0.85, green: 0.65, blue: 0.13)]),
                                startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: size.height)
                            ))
                            
                            // Draw decorative pattern
                            context.drawLayer { ctx in
                                for i in stride(from: 0, to: size.width, by: 20) {
                                    for j in stride(from: 0, to: size.height, by: 20) {
                                        let dot = Path(ellipseIn: CGRect(x: i + 8, y: j + 8, width: 4, height: 4))
                                        ctx.fill(dot, with: .color(.white.opacity(0.15)))
                                    }
                                }
                            }
                            
                            // Draw "Raspa aquí" text
                            context.draw(Text("✨ Raspa aquí ✨").font(.system(.title2, design: .rounded, weight: .bold)).foregroundColor(.white), at: CGPoint(x: size.width / 2, y: size.height / 2 - 10), anchor: .center)
                            context.draw(Text("👆 Arrastra el dedo").font(.system(.caption, design: .rounded, weight: .medium)).foregroundColor(.white.opacity(0.8)), at: CGPoint(x: size.width / 2, y: size.height / 2 + 20), anchor: .center)
                            
                            // Erase scratched areas
                            context.blendMode = .clear
                            for point in scratchPoints {
                                let scratchRect = CGRect(x: point.x - 20, y: point.y - 20, width: 40, height: 40)
                                context.fill(Path(ellipseIn: scratchRect), with: .color(.black))
                            }
                        }
                        .frame(width: 280, height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    scratchPoints.append(value.location)
                                    // Calculate scratch percentage
                                    let totalArea: Double = 280 * 280
                                    let scratchedArea = Double(scratchPoints.count) * (40 * 40)
                                    scratchPercentage = min(scratchedArea / totalArea, 1.0)
                                    
                                    // Auto-reveal at 40%
                                    if scratchPercentage > 0.4 && !isScratched {
                                        Task {
                                            if let id = scratchCard?.id {
                                                try? await APIService.shared.scratchCard(id: id)
                                                let generator = UINotificationFeedbackGenerator()
                                                generator.notificationOccurred(.success)
                                                AmbientAudio.shared.playSuccess()
                                                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                                    isScratched = true
                                                }
                                                // Trigger Confetti Burst
                                                confettiManager.burst()
                                            }
                                        }
                                    } else {
                                        // Haptic on scratch
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    }
                                }
                        )
                        .shadow(color: Color(red: 0.85, green: 0.65, blue: 0.13).opacity(0.4), radius: 12, y: 6)
                    }
                }
                
                // Progress indicator
                if !isScratched {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.draw.fill").foregroundStyle(.orange)
                        Text("\(Int(scratchPercentage * 100))% rascado")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(32)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showScratchSheet = false; isScratched = false; scratchPoints = []; scratchPercentage = 0; Task { await loadData() } } } } }
        }
        .background(Theme.meshBackground.ignoresSafeArea())
        .overlay { ConfettiView(manager: confettiManager).ignoresSafeArea() }
    }
    
    // MARK: - Throwback Memory Card
    @ViewBuilder
    private var throwbackMemoryCard: some View {
        if photos.count > 3, let randomOldPhoto = photos.dropFirst(2).randomElement(), let imgData = randomOldPhoto.imageData, !imgData.isEmpty, let d = Data(base64Encoded: imgData), let uiImg = UIImage(data: d) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.rosePrimary)
                    Text("Un día como hoy...")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                }
                
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onTapGesture { fullScreenPhoto = uiImg }
                    .contextMenu {
                        Button {
                            UIImageWriteToSavedPhotosAlbum(uiImg, nil, nil, nil)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: { Label("Guardar en Fotos", systemImage: "square.and.arrow.down") }
                    } preview: {
                        Image(uiImage: uiImg).resizable().aspectRatio(contentMode: .fit)
                    }
                
                if !randomOldPhoto.caption.isEmpty {
                    Text(randomOldPhoto.caption)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .italic()
                }
            }
            .padding(20)
            .background(Theme.glassCard(cornerRadius: 24))
        }
    }
    
    // MARK: - Roulette Preview
    private var roulettePreviewCard: some View {
        Button { showRouletteSheet = true } label: {
            HStack {
                Text("🎲").font(.system(size: 36))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ruleta de Decisiones")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.rosePrimary)
                    Text(rouletteOptions.isEmpty ? "Agrega opciones para girar" : "\(rouletteOptions.count) opciones disponibles")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90").font(.title2).foregroundStyle(.blue)
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.ultraThinMaterial).shadow(color: Theme.rosePrimary.opacity(0.1), radius: 8, y: 4))
        }
    }
    
    // MARK: - Roulette Sheet
    private var rouletteSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let result = rouletteResult {
                    VStack(spacing: 12) {
                        Text("🎯").font(.system(size: 60))
                        Text(result)
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)
                    }
                    .padding(30)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Theme.rosePrimary.opacity(0.1)))
                }
                
                Button {
                    guard !rouletteOptions.isEmpty else { return }
                    withAnimation { isSpinning = true; rouletteResult = nil }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        let random = rouletteOptions.randomElement()!
                        withAnimation(.spring()) { rouletteResult = random.optionText; isSpinning = false }
                    }
                } label: {
                    HStack {
                        if isSpinning { ProgressView().tint(.white) }
                        Text(isSpinning ? "Girando..." : "🎲 ¡Girar!")
                    }
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40).padding(.vertical, 14)
                    .background(Capsule().fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)))
                }
                .disabled(isSpinning || rouletteOptions.isEmpty)
                
                Divider()
                HStack {
                    TextField("Nueva opción...", text: $newRouletteOption)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        guard !newRouletteOption.isEmpty else { return }
                        Task {
                            try? await APIService.shared.createRouletteOption(category: "general", optionText: newRouletteOption, addedBy: isAdmin ? "admin" : "girlfriend")
                            newRouletteOption = ""
                            rouletteOptions = (try? await APIService.shared.fetchRouletteOptions(category: "general")) ?? []
                        }
                    } label: { Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(Theme.rosePrimary) }
                }
                
                List {
                    ForEach(rouletteOptions) { opt in
                        HStack {
                            Text(opt.optionText)
                            Spacer()
                            Text(opt.addedBy == "admin" ? "👨" : "👩").font(.caption)
                        }
                    }
                }.listStyle(.plain)
            }.padding(20)
            .navigationTitle("Ruleta 🎲")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { showRouletteSheet = false; rouletteResult = nil } } }
        }
    }
    
    // MARK: - Diary Preview
    private var diaryPreviewCard: some View {
        Button { withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showDiarySheet = true } } label: {
            HStack {
                Text("📖").font(.system(size: 36))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Diario Compartido")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.rosePrimary)
                    Text(partnerDiary.isEmpty ? "Escribe sobre tu día" : "\(partnerDiary.count) entradas de tu pareja")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "pencil.line").font(.title2).foregroundStyle(.green).symbolEffect(.pulse)
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.ultraThinMaterial).shadow(color: Theme.rosePrimary.opacity(0.1), radius: 8, y: 4))
            .matchedGeometryEffect(id: "diaryGeo", in: exploreAnimation)
        }
    }
    
    // MARK: - Diary Sheet
    private var diarySheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("¿Qué pasó hoy?").font(.system(.headline, design: .rounded, weight: .bold))
                        TextEditor(text: $diaryText)
                            .frame(minHeight: 120)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                        Button {
                            Task {
                                try? await APIService.shared.writeDiaryEntry(author: isAdmin ? "admin" : "girlfriend", content: diaryText)
                                showToast("Diario guardado 📖")
                                diaryText = ""
                            }
                        } label: {
                            Text("Guardar")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24).padding(.vertical, 10)
                                .background(Capsule().fill(Theme.rosePrimary))
                        }
                        .disabled(diaryText.isEmpty)
                    }
                    
                    if !partnerDiary.isEmpty {
                        Divider()
                        Text("Entradas de tu pareja").font(.system(.headline, design: .rounded, weight: .bold))
                        ForEach(partnerDiary) { entry in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(entry.entryDate ?? "").font(.caption).foregroundStyle(.tertiary)
                                Text(entry.content ?? "").font(.system(.body, design: .rounded))
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.rosePrimary.opacity(0.05)))
                        }
                    }
                }.padding(20)
            }
            .navigationTitle("Diario 📖")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showDiarySheet = false } } } }
        }
        .background(Theme.meshBackground.ignoresSafeArea())
    }
    
    // MARK: - Points Preview
    private var pointsPreviewCard: some View {
        Button { showRewardsSheet = true } label: {
            HStack {
                Text("🏆").font(.system(size: 36))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mis Puntos")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.rosePrimary)
                    Text("\(pointsBalance) puntos disponibles")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(pointsBalance)")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.yellow)
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.ultraThinMaterial).shadow(color: Theme.rosePrimary.opacity(0.1), radius: 8, y: 4))
        }
    }
    
    // MARK: - Rewards Sheet
    private var rewardsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Text("🏆").font(.system(size: 50))
                        VStack(alignment: .leading) {
                            Text("\(pointsBalance)").font(.system(.largeTitle, design: .rounded, weight: .bold)).foregroundStyle(.yellow)
                            Text("puntos disponibles").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Theme.rosePrimary.opacity(0.05)))
                    
                    ForEach(rewards.filter { !$0.redeemed }) { reward in
                        HStack {
                            Text(reward.emoji).font(.title)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(reward.title).font(.system(.subheadline, design: .rounded, weight: .semibold))
                                Text("\(reward.cost) puntos").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                Task {
                                    try? await APIService.shared.redeemReward(id: reward.id, redeemedBy: isAdmin ? "admin" : "girlfriend")
                                    rewards = (try? await APIService.shared.fetchRewards()) ?? []
                                    let pts = try? await APIService.shared.fetchPoints(username: isAdmin ? "admin" : "girlfriend")
                                    pointsBalance = pts?.balance ?? 0
                                    showToast("¡Canjeado! 🎉")
                                }
                            } label: {
                                Text("Canjear")
                                    .font(.system(.caption, design: .rounded, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14).padding(.vertical, 6)
                                    .background(Capsule().fill(pointsBalance >= reward.cost ? Theme.rosePrimary : Color.gray))
                            }
                            .disabled(pointsBalance < reward.cost)
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                    }
                }.padding(20)
            }
            .navigationTitle("Recompensas 🎁")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { showRewardsSheet = false } } }
        }
    }
    
    // MARK: - Experiences Preview
    private var experiencesPreviewCard: some View {
        Button { showExperiencesSheet = true } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Lista de Experiencias", systemImage: "checklist")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.rosePrimary)
                    Spacer()
                    let done = experiences.filter { $0.completed }.count
                    Text("\(done)/\(experiences.count)")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(experiences.prefix(6)) { exp in
                        VStack(spacing: 4) {
                            Text(exp.emoji).font(.system(size: 28)).opacity(exp.completed ? 1 : 0.4)
                            Text(exp.title)
                                .font(.system(.caption2, design: .rounded, weight: .medium))
                                .foregroundStyle(exp.completed ? .primary : .secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 12).fill(exp.completed ? Theme.rosePrimary.opacity(0.08) : Color.gray.opacity(0.05)))
                    }
                }
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).shadow(color: Theme.rosePrimary.opacity(0.1), radius: 8, y: 4))
        }
    }
    
    // MARK: - Experiences Sheet
    private var experiencesSheet: some View {
        NavigationStack {
            experiencesSheetContent
                .navigationTitle("Experiencias ✨")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cerrar") { showExperiencesSheet = false }
                    }
                }
        }
    }

    private var experiencesSheetContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                let done = experiences.filter { $0.completed }.count
                Text("\(done) de \(experiences.count) completadas")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                ForEach(experiences) { exp in
                    experienceRow(exp)
                }
            }
            .padding(20)
        }
    }

    private func experienceRow(_ exp: Experience) -> some View {
        HStack {
            Text(exp.emoji).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(exp.title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .strikethrough(exp.completed)
                if !exp.description.isEmpty {
                    Text(exp.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            if exp.completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            } else {
                Button {
                    Task {
                        try? await APIService.shared.completeExperience(id: exp.id, photo: nil)
                        experiences = (try? await APIService.shared.fetchExperiences()) ?? []
                        AmbientAudio.shared.playSuccess()
                        showToast("¡Experiencia completada! 🎉")
                    }
                } label: {
                    Text("Hecho")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.rosePrimary))
                }
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(exp.completed ? AnyShapeStyle(Theme.rosePrimary.opacity(0.05)) : AnyShapeStyle(.ultraThinMaterial))
        }
    }
}

// MARK: - Date Plan Swipe Cards (Tinder Style)
struct DatePlanSwipeView: View {
    @Binding var plans: [DatePlan]
    let isAdmin: Bool
    let onRefresh: () -> Void
    
    var pendingPlans: [DatePlan] {
        plans.filter { $0.status == "pendiente" }
    }
    
    var body: some View {
        VStack {
            ZStack {
                if pendingPlans.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "heart.square.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.rosePrimary)
                            .symbolEffect(.pulse)
                        Text("No hay planes pendientes")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 180)
                } else {
                    // Render cards backwards so the first is on top
                    ForEach(pendingPlans.reversed()) { plan in
                        SwipeablePlanCard(plan: plan, isAdmin: isAdmin) { accepted in
                            Task {
                                try? await APIService.shared.updatePlanStatus(id: plan.id, status: accepted ? "aceptado" : "rechazado")
                                onRefresh()
                            }
                        }
                    }
                }
            }
            .frame(height: 180)
            
            // Accepted Plans Summary Below
            let accepted = plans.filter { $0.status == "aceptado" }
            if !accepted.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Planes Aceptados").font(.caption).foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(accepted) { plan in
                                Text("\(plan.title) 💖")
                                    .font(.system(.caption, design: .rounded, weight: .bold))
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Capsule().fill(.ultraThinMaterial))
                            }
                        }
                    }
                }
                .padding(.top, 12)
            }
        }
    }
}

struct SwipeablePlanCard: View {
    let plan: DatePlan
    let isAdmin: Bool
    let onSwipe: (Bool) -> Void // True = Accept (Right), False = Reject (Left)
    
    @State private var offset: CGSize = .zero
    @State private var color: Color = .white
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(plan.title).font(.system(.title3, design: .rounded, weight: .bold)).foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(plan.category.capitalized).font(.system(size: 10, weight: .bold)).foregroundStyle(.white).padding(.horizontal, 8).padding(.vertical, 4).background(Capsule().fill(Theme.rosePrimary))
            }
            
            Text(plan.description)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            HStack {
                Image(systemName: "calendar")
                Text(formatDate(plan.proposedDate))
                Spacer()
                Image(systemName: "clock")
                Text(plan.proposedTime)
            }
            .font(.system(.caption, design: .rounded, weight: .medium))
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(height: 180)
        .background(Theme.glassCard(cornerRadius: 24))
        .background(RoundedRectangle(cornerRadius: 24).fill(color.opacity(0.8)))
        .offset(x: offset.width, y: offset.height * 0.4)
        .rotationEffect(.degrees(Double(offset.width / 15)))
        // Swiping gesture logic
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    withAnimation {
                        if offset.width > 50 { color = .green }
                        else if offset.width < -50 { color = .red }
                        else { color = .white }
                    }
                }
                .onEnded { _ in
                    let swipeThreshold: CGFloat = 100
                    if offset.width > swipeThreshold {
                        // Swiped Right - Accept
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        onSwipe(true)
                    } else if offset.width < -swipeThreshold {
                        // Swiped Left - Reject
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        onSwipe(false)
                    } else {
                        // Snap back
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            offset = .zero
                            color = .white
                        }
                    }
                }
        )
        // Admin shouldn't swipe if it's the girlfriend's app logic, but let's allow it for testing if needed
    }
    
    private func formatDate(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateStr) {
            let df = DateFormatter()
            df.dateFormat = "dd/MM"
            return df.string(from: date)
        }
        return dateStr
    }
}
