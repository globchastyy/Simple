
public protocol JSONConvertable { }

public extension JSONConvertable {
    public var jsonObject: [String: Any] {
        var result = [String: Any]()

        for property in Mirror(reflecting: self).children {
            if let label = property.label {
                if let value = property.value as? [JSONConvertable] {
                    result[label] = value.map { $0.jsonObject }
                } else {
                    result[label] = property.value
                }
            }
        }

        return result
    }
}
