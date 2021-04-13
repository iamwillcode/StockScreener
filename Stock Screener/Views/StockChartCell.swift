import UIKit
import Charts

final class StockChartCell: UITableViewCell {
    
    //MARK: - Public properties
    
    lazy var stockChartView: LineChartView = {
        let chartView = ChartView()
        chartView.leftAxis.enabled = false
        chartView.xAxis.enabled = false
        chartView.rightAxis.enabled = false
        chartView.noDataText = "Waiting for the chart data..."
        chartView.legend.enabled = false
        chartView.dragEnabled = true
        chartView.setScaleEnabled(false)
        return chartView
    }()
    
    lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.hidesWhenStopped = true
        indicator.color = .black
        indicator.style = .large
        return indicator
    }()
    
    //MARK: - Private properties
    
    private let stockBuilder = StockBuilder()
    private let detailViewController = DetailViewController()
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupCell()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    //MARK: - Public Methods
    
    func setData(for ticker: String, completion: @escaping (Bool) -> Void) {
        var entries = [ChartDataEntry]()
        
        self.stockBuilder.getChartData(for: ticker) { (result) in
            var n: Double = 0
            
            for element in result {
                let chartDataEntry = ChartDataEntry(x: n, y: element)
                n += 1
                entries.append(chartDataEntry)
            }
            
            let chartDataSet = LineChartDataSet(entries: entries, label: "Highest price")
            chartDataSet.drawCirclesEnabled = false
            chartDataSet.mode = .cubicBezier
            chartDataSet.lineWidth = 3
            chartDataSet.setColor(UIColor(named: K.Colors.Brand.main)!)
            chartDataSet.fill = Fill(color: UIColor(named: K.Colors.Brand.main)!)
            chartDataSet.fillAlpha = 0.5
            chartDataSet.drawFilledEnabled = true
            chartDataSet.drawHorizontalHighlightIndicatorEnabled = false
            chartDataSet.highlightEnabled = true
            chartDataSet.highlightColor = UIColor(named: K.Colors.Brand.main)!
            chartDataSet.highlightLineWidth = 2
            
            let data = LineChartData(dataSet: chartDataSet)
            data.setDrawValues(false)
            
            DispatchQueue.main.async {
                self.stockChartView.data = data
                completion(true)
            }
        }
    }
    
    //MARK: - Private methods
    
    private func setupCell() {
        self.heightAnchor.constraint(equalToConstant: 300).isActive = true
        
        self.addSubview(stockChartView)
        stockChartView.translatesAutoresizingMaskIntoConstraints = false
        stockChartView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5.0).isActive = true
        stockChartView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5.0).isActive = true
        stockChartView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0.0).isActive = true
        stockChartView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0.0).isActive = true
        
        self.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        activityIndicator.heightAnchor.constraint(equalToConstant: 50).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
}
