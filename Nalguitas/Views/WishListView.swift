import SwiftUI
import PhotosUI

struct WishListView: View {
    let isAdmin: Bool
    @State private var items: [WishItem] = []
    @State private var isLoading = false
    @State private var showAddSheet = false
    
    // Add form
    @State private var newName = ""
    @State private var newLink = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isAdding = false
    
    @Environment(\.dismiss) private var dismiss
    
    private var addedBy: String { isAdmin ? "admin" : "girlfriend" }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.meshBackground
                
                if isLoading {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(0..<4, id: \.self) { _ in
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(width: 70, height: 70)
                                    VStack(alignment: .leading, spacing: 8) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.gray.opacity(0.15))
                                            .frame(width: 150, height: 16)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.gray.opacity(0.15))
                                            .frame(width: 80, height: 12)
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                                .shimmering()
                            }
                        }
                        .padding(16)
                    }
                    .scrollIndicators(.hidden)
                } else if items.isEmpty {
                    emptyState
                } else {
                    itemsList
                }
            }
            .navigationTitle("Lista de Deseos 💝")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
                if !isAdmin {
                    ToolbarItem(placement: .confirmationAction) {
                        Button { showAddSheet = true } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Theme.rosePrimary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) { addItemSheet }
            .task { await loadItems() }
            .refreshable { await loadItems() }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "gift")
                .font(.system(size: 48))
                .foregroundStyle(Theme.roseLight)
                .symbolEffect(.breathe, options: .repeating)
            
            Text(isAdmin ? "Tu novia aún no ha agregado deseos" : "Tu lista está vacía")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
            
            if !isAdmin {
                Text("Agrega lo que quieras y él lo verá 💕")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.tertiary)
                
                Button { showAddSheet = true } label: {
                    Label("Agregar deseo", systemImage: "plus.circle.fill")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Theme.accentGradient))
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Items List
    private var itemsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(items) { item in
                    wishItemCard(item)
                        .scrollTransition(.animated.threshold(.visible(0.3))) { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1 : 0.8)
                                .scaleEffect(phase.isIdentity ? 1 : 0.95)
                                .blur(radius: phase.isIdentity ? 0 : 2)
                        }
                        .contextMenu {
                            if let link = item.link, !link.isEmpty, let url = URL(string: link) {
                                Button {
                                    UIApplication.shared.open(url)
                                } label: {
                                    Label("Abrir Link", systemImage: "safari")
                                }
                            }
                            if isAdmin {
                                Button(role: .destructive) {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    Task { await deleteItem(item) }
                                } label: {
                                    Label("Marcar como Obtenido", systemImage: "checkmark.circle.fill")
                                }
                            }
                        } preview: {
                            wishItemCard(item).frame(width: 320).padding()
                        }
                }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
    }
    
    private func wishItemCard(_ item: WishItem) -> some View {
        HStack(spacing: 12) {
            // Photo
            if let imgStr = item.imageData, !imgStr.isEmpty,
               let data = Data(base64Encoded: imgStr),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.rosePale)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: "gift.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.rosePrimary.opacity(0.4))
                    )
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                
                if let link = item.link, !link.isEmpty {
                    Link(destination: URL(string: link) ?? URL(string: "https://google.com")!) {
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                                .font(.system(size: 10))
                            Text("Ver producto")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(Theme.rosePrimary)
                    }
                }
                
                Text(item.addedBy == "admin" ? "Isacc" : "Tucancita")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            // Admin can mark as gotten
            if isAdmin {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    Task { await deleteItem(item) }
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Theme.rosePrimary.opacity(0.06), radius: 8, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.6), Theme.roseLight.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
        )
    }
    
    // MARK: - Add Item Sheet
    private var addItemSheet: some View {
        NavigationStack {
            ZStack {
                Theme.meshBackground
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Photo picker
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            if let data = selectedImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(Theme.rosePrimary)
                                    Text("Agregar foto")
                                        .font(.system(.caption, design: .rounded, weight: .medium))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                .frame(width: 120, height: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .stroke(Theme.roseLight, style: StrokeStyle(lineWidth: 1, dash: [6]))
                                        )
                                )
                            }
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                }
                            }
                        }
                        
                        // Name
                        TextField("¿Qué quieres?", text: $newName)
                            .font(.system(.body, design: .rounded))
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Theme.roseLight, lineWidth: 0.5)
                                    )
                            )
                        
                        // Link
                        TextField("Link del producto (opcional)", text: $newLink)
                            .font(.system(.body, design: .rounded))
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Theme.roseLight, lineWidth: 0.5)
                                    )
                            )
                        
                        // Add button
                        Button {
                            Task { await addItem() }
                        } label: {
                            HStack {
                                if isAdding {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "heart.fill")
                                    Text("Agregar a mi lista")
                                }
                            }
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(Theme.accentGradient))
                        }
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty || isAdding)
                        .opacity(newName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Nuevo Deseo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showAddSheet = false }
                }
            }
        }
    }
    
    // MARK: - Actions
    private func loadItems() async {
        isLoading = items.isEmpty
        defer { isLoading = false }
        items = (try? await APIService.shared.fetchWishList()) ?? []
    }
    
    private func addItem() async {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        isAdding = true
        defer { isAdding = false }
        
        let imgBase64 = selectedImageData?.base64EncodedString()
        let link = newLink.trimmingCharacters(in: .whitespaces)
        
        if let item = try? await APIService.shared.addWishItem(
            name: name,
            link: link.isEmpty ? nil : link,
            imageData: imgBase64,
            addedBy: addedBy
        ) {
            items.insert(item, at: 0)
            newName = ""
            newLink = ""
            selectedImageData = nil
            selectedPhotoItem = nil
            showAddSheet = false
        }
    }
    
    private func deleteItem(_ item: WishItem) async {
        try? await APIService.shared.deleteWishItem(id: item.id)
        items.removeAll { $0.id == item.id }
    }
}
