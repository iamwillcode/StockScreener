import Foundation
import RealmSwift

final class StockObject: Object {
    @objc dynamic var key = ""
    @objc dynamic var value: StockModelObject?
    
    override static func primaryKey() -> String? {
        return "key"
    }
}
