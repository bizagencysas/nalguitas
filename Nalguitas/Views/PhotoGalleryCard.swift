import SwiftUI

struct PhotoGalleryCard: View {
    let photo: SharedPhoto
    var width: CGFloat? = nil
    var height: CGFloat = 90
    var cornerRadius: CGFloat = 12
    var onTap: ((UIImage) -> Void)? = nil

    @State private var image: UIImage?
    @State private var isLoading = false

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
        let b64 = photo.imageData

        if let cached = PhotoStore.shared.load(id: photoId) {
            image = cached
            return
        }
        guard let b64str = b64, !b64str.isEmpty else { return }
        isLoading = true
        await PhotoStore.shared.save(base64: b64str, id: photoId)
        image = PhotoStore.shared.load(id: photoId)
        isLoading = false
    }
}
