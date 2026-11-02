import Foundation
import ImageIO
import UniformTypeIdentifiers

enum CardImageStoreError: LocalizedError {
    case invalidRelativePath
    case emptyImageData

    var errorDescription: String? {
        switch self {
        case .invalidRelativePath:
            "图片路径无效。"
        case .emptyImageData:
            "所选图片没有可保存的数据。"
        }
    }
}

struct CardImageStore: Sendable {
    nonisolated static let live = CardImageStore()

    let baseDirectory: URL

    nonisolated init(baseDirectory: URL? = nil) {
        if let baseDirectory {
            self.baseDirectory = baseDirectory
        } else {
            self.baseDirectory = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first ?? FileManager.default.temporaryDirectory
        }
    }

    nonisolated func save(_ data: Data, for id: UUID) throws -> String {
        guard !data.isEmpty else { throw CardImageStoreError.emptyImageData }
        let directory = imageDirectory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let filename = "\(id.uuidString).\(preferredExtension(for: data))"
        let destination = directory.appendingPathComponent(filename, isDirectory: false)
        try data.write(to: destination, options: [.atomic])
        return "CardImages/\(filename)"
    }

    nonisolated func load(relativePath: String?) throws -> Data? {
        guard let relativePath, !relativePath.isEmpty else { return nil }
        let url = try resolvedURL(for: relativePath)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try Data(contentsOf: url)
    }

    nonisolated func delete(relativePath: String?) throws {
        guard let relativePath, !relativePath.isEmpty else { return }
        let url = try resolvedURL(for: relativePath)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    nonisolated func removeAllImages() throws {
        guard FileManager.default.fileExists(atPath: imageDirectory.path) else { return }
        try FileManager.default.removeItem(at: imageDirectory)
    }

    nonisolated private var imageDirectory: URL {
        baseDirectory.appendingPathComponent("CardImages", isDirectory: true)
    }

    nonisolated private func resolvedURL(for relativePath: String) throws -> URL {
        let components = NSString(string: relativePath).pathComponents
        guard components.count == 2,
              components[0] == "CardImages",
              components[1] != ".",
              components[1] != ".." else {
            throw CardImageStoreError.invalidRelativePath
        }

        let url = baseDirectory.appendingPathComponent(relativePath).standardizedFileURL
        let allowedPrefix = imageDirectory.standardizedFileURL.path + "/"
        guard url.path.hasPrefix(allowedPrefix) else {
            throw CardImageStoreError.invalidRelativePath
        }
        return url
    }

    nonisolated private func preferredExtension(for data: Data) -> String {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source) else { return "img" }
        return UTType(type as String)?.preferredFilenameExtension ?? "img"
    }
}
