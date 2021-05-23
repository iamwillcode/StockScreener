import Foundation
import Charts

/// Custom chart with tap recognizer
final class ChartView: LineChartView {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        addTapRecognizer()
    }
    

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addTapRecognizer()
    }
    
    func addTapRecognizer() {
        let tapRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chartTapped))
        tapRecognizer.minimumPressDuration = 0.01
        self.addGestureRecognizer(tapRecognizer)
    }
    
    @objc func chartTapped(_ sender: UITapGestureRecognizer) {
        if sender.state == .began || sender.state == .changed {
            let position = sender.location(in: self)
            let highlight = self.getHighlightByTouchPoint(position)
            let entry = self.getEntryByTouchPoint(point: position)
            
            guard let h = highlight, // swiftlint:disable:this identifier_name
                  let e = entry else { return } // swiftlint:disable:this identifier_name
            
            highlightValue(h)
            
            // Send entry and highlight position to the delegate when a tap was recognized
            delegate?.chartValueSelected?(self, entry: e, highlight: h)
        } else {
            highlightValue(nil)
            delegate?.chartValueNothingSelected?(self)
        }
    }
}
