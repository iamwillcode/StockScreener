import UIKit
import RealmSwift

final class StockModelObject: Object {
    @objc dynamic var ticker = ""
    @objc dynamic var companyName = ""
    
    override static func primaryKey() -> String? {
        return "ticker"
    }
}
