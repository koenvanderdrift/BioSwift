import Foundation

public struct Resource<A> {
    public let url: URL
    public let parse: (Data) -> A?
}

extension Resource {
    public init(url: URL, parseFasta: @escaping ([Fasta]) -> A?) {
        self.url = url
        parse = { data in
            let fasta = Fasta(data: data, encoding: .utf8)?.components(separatedBy: ">")
            return fasta.flatMap(parseFasta)
        }
    }
}

public final class Webservice {
    public init() {}

    public func load<A>(resource: Resource<A>, completion: @escaping (A?) -> Void) {
        URLSession.shared.dataTask(with: resource.url) { data, _, _ in
            let result = data.flatMap(resource.parse)
            completion(result)
        }.resume()
    }
}
