import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    
    private let baseURL = "https://nalguitas-backend.onrender.com/api"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        setupUI()
        handleSharedContent()
    }
    
    private func setupUI() {
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurView)
        
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 20
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowRadius = 10
        containerView.translatesAutoresizingMaskIntoConstraints = false
        blurView.contentView.addSubview(containerView)
        
        let heartLabel = UILabel()
        heartLabel.text = "💕"
        heartLabel.font = .systemFont(ofSize: 50)
        heartLabel.textAlignment = .center
        heartLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(heartLabel)
        
        let titleLabel = UILabel()
        titleLabel.text = "Enviando a Nalguitas..."
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor(red: 0.94, green: 0.32, blue: 0.53, alpha: 1.0)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(spinner)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: blurView.contentView.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 260),
            containerView.heightAnchor.constraint(equalToConstant: 180),
            heartLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            heartLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: heartLabel.bottomAnchor, constant: 12),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            spinner.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])
    }
    
    private func handleSharedContent() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            close(); return
        }
        
        for item in extensionItems {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                // Handle URLs (TikTok, Instagram, YouTube, etc.)
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] data, _ in
                        if let url = data as? URL {
                            self?.sendToChat(type: "link", content: url.absoluteString, mediaUrl: url.absoluteString)
                        } else if let urlData = data as? Data, let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                            self?.sendToChat(type: "link", content: url.absoluteString, mediaUrl: url.absoluteString)
                        }
                    }
                    return
                }
                // Handle text (might contain URLs)
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] data, _ in
                        if let text = data as? String {
                            let type = text.contains("http") ? "link" : "text"
                            self?.sendToChat(type: type, content: text, mediaUrl: text.contains("http") ? text : nil)
                        }
                    }
                    return
                }
                // Handle images
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] data, _ in
                        var imageData: Data?
                        if let url = data as? URL {
                            imageData = try? Data(contentsOf: url)
                        } else if let img = data as? UIImage {
                            imageData = img.jpegData(compressionQuality: 0.4)
                        }
                        if let imgData = imageData {
                            let base64 = imgData.base64EncodedString()
                            self?.sendToChat(type: "image", content: "📷", mediaData: base64)
                        }
                    }
                    return
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.close()
        }
    }
    
    private func sendToChat(type: String, content: String, mediaData: String? = nil, mediaUrl: String? = nil) {
        let role = UserDefaults.standard.string(forKey: "isAdminDevice") == "true" ? "admin" : "girlfriend"
        
        var body: [String: Any] = ["sender": role, "type": type, "content": content]
        if let md = mediaData { body["mediaData"] = md }
        if let mu = mediaUrl { body["mediaUrl"] = mu }
        
        guard let url = URL(string: "\(baseURL)/chat/send"),
              let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            close(); return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { [weak self] _, _, _ in
            DispatchQueue.main.async {
                self?.showSuccess()
            }
        }.resume()
    }
    
    private func showSuccess() {
        // Clear existing UI
        view.subviews.forEach { $0.removeFromSuperview() }
        
        let successStack = UIStackView()
        successStack.axis = .vertical
        successStack.alignment = .center
        successStack.spacing = 8
        successStack.translatesAutoresizingMaskIntoConstraints = false
        
        let checkLabel = UILabel()
        checkLabel.text = "✅"
        checkLabel.font = .systemFont(ofSize: 50)
        successStack.addArrangedSubview(checkLabel)
        
        let sentLabel = UILabel()
        sentLabel.text = "Enviado a tu chat 💕"
        sentLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        sentLabel.textColor = UIColor(red: 0.94, green: 0.32, blue: 0.53, alpha: 1.0)
        successStack.addArrangedSubview(sentLabel)
        
        view.addSubview(successStack)
        NSLayoutConstraint.activate([
            successStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            successStack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.close()
        }
    }
    
    private func close() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
