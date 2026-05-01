import Foundation
import Yams

public enum PromptLoader {
    public static func loadBuiltIns(bundle: Bundle? = nil) -> [PromptTemplate] {
        let resolved = bundle ?? .module
        let ids = PromptTemplate.BuiltInID.allCases.map(\.rawValue)
        return ids.compactMap { id in
            guard let url = resolved.url(forResource: id, withExtension: "yaml", subdirectory: "Prompts")
                ?? resolved.url(forResource: id, withExtension: "yaml") else {
                return nil
            }
            return try? load(url: url)
        }
    }

    public static func load(url: URL) throws -> PromptTemplate {
        let raw = try String(contentsOf: url, encoding: .utf8)
        return try parse(yaml: raw)
    }

    public static func parse(yaml: String) throws -> PromptTemplate {
        struct DTO: Codable {
            let id: String
            let name: String
            let system: String
            let user_template: String
            let hotwords: [String]?
        }
        let decoder = YAMLDecoder()
        let dto = try decoder.decode(DTO.self, from: yaml)
        return PromptTemplate(
            id: dto.id,
            name: dto.name,
            system: dto.system,
            userTemplate: dto.user_template,
            hotwords: dto.hotwords ?? []
        )
    }
}
