import Foundation
import Charts

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
            let dataSet = self.getDataSetByTouchPoint(point: position)
            dataSet?.drawValuesEnabled = true
            highlightValue(highlight)
        } else {
            data?.dataSets.forEach{ $0.drawValuesEnabled = false }
            highlightValue(nil)
        }
    }
    
}
