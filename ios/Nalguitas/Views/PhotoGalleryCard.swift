import SwiftUI

struct PhotoGalleryCard: View {
    let photo: SharedPhoto
    var width: CGFloat? = nil
    var height: CGFloat = 90
    var cornerRadius: CGFloat = 12
    var onTap: ((UIImage) -> Void)? = nil

    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var failed = false

    var body: some View {
        Color(.secondarySystemBackground)
            .frame(width: width, height: height)
            .overlay {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                } else {
                    Group {
                        if isLoading {
                            ProgressView()
                                .tint(Theme.rosePrimary)
                                .scaleEffect(0.8)
                        } else if failed {
                            Image(systemName: "exclamationmark.circle")
                                .font(.title2)
                                .foregroundStyle(.secondary.opacity(0.5))
                        } else {
                            Image(systemName: "photo.fill")
                                .font(.title2)
                                .foregroundStyle(Theme.rosePrimary.opacity(0.35))
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .onTapGesture {
                if let img = image { onTap?(img) }
            }
            .contextMenu {
                if let img = image {
                    Button {
                        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        Label("Guardar en Fotos", systemImage: "square.and.arrow.down")
                    }
                }
            } preview: {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .task(id: photo.id) { await loadImage() }
    }

    private func loadImage() async {
        let photoId = photo.id

        if let cached = PhotoStore.shared.load(id: photoId) {
            image = cached
            return
        }

        if let b64str = photo.imageData, !b64str.isEmpty {
            isLoading = true
            await PhotoStore.shared.save(base64: b64str, id: photoId)
            image = PhotoStore.shared.load(id: photoId)
            isLoading = false
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await APIService.shared.fetchPhotoById(id: photoId)
            if let b64 = fetched.imageData, !b64.isEmpty {
                await PhotoStore.shared.save(base64: b64, id: photoId)
                image = PhotoStore.shared.load(id: photoId)
            } else {
                failed = true
            }
        } catch {
            failed = true
        }
    }
}
