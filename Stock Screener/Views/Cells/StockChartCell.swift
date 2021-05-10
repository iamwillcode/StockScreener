import UIKit
import Charts

final class StockChartCell: UITableViewCell {
    
    // Use to convert x-axis labels from UNIX-timestamp to date when initialize Chart View
    
    final class XAxisLabelFormatter: NSObject, IAxisValueFormatter {
        
        func stringForValue( _ value: Double, axis _: AxisBase?) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM"
            let formattedDate = formatter.string(from: Date(timeIntervalSince1970: value))
            return formattedDate
        }
    }
    
    //MARK: - Public properties
    
    lazy var stockChartView: LineChartView = {
        let chartView = ChartView()
        chartView.leftAxis.enabled = false
        chartView.xAxis.enabled = false
        chartView.xAxis.labelPosition = .bottomInside
        chartView.xAxis.granularity = 1
        chartView.xAxis.valueFormatter = XAxisLabelFormatter()
        chartView.xAxis.labelTextColor = K.Colors.Text.ternary
        chartView.xAxis.drawAxisLineEnabled = false
        chartView.xAxis.labelCount = 8
        chartView.rightAxis.enabled = false
        chartView.legend.enabled = false
        chartView.dragEnabled = true
        chartView.setScaleEnabled(false)
        chartView.noDataText = "Waiting for the chart data..."
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
    
    private let stockManager = StockManager()
    private let detailViewController = DetailViewController()
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupUI()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupLayout()
    }
    
    //MARK: - Public Methods
    
    func setData(for ticker: String, completion: @escaping (Bool) -> Void) {
        
        var entries = [ChartDataEntry]()
        
        stockManager.getChartData(for: ticker) { (prices, timestamps) in
            
            // Convert two arrays into array of tuples
            
            let axisData = zip(timestamps, prices).map { ($0, $1) }
            
            // Initialize Chart Data Entries from axisData elements
            
            for (xAxisData, yAxisData) in axisData {
                let chartDataEntry = ChartDataEntry(x: xAxisData, y: yAxisData)
                entries.append(chartDataEntry)
            }
            
            // Setup the chart color by calculating a median of prices
            
            let median = prices.sorted(by: <)[prices.count / 2]
            
            var chartColor: UIColor {
                let lastPrice = entries[entries.count - 1].y
                if lastPrice >= median {
                    return K.Colors.Common.green
                } else {
                    return K.Colors.Common.red
                }
            }
            
            // Setup Chart Data Set
            
            let chartDataSet = LineChartDataSet(entries: entries, label: "Price change")
            chartDataSet.drawCirclesEnabled = false
            chartDataSet.mode = .cubicBezier
            chartDataSet.lineWidth = 3
            chartDataSet.setColor(chartColor)
            let gradientColors = [K.Colors.Background.secondary.cgColor, chartColor.cgColor]
            let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!
            chartDataSet.fill = Fill(linearGradient: gradient, angle: 90)
            chartDataSet.fillAlpha = 0.5
            chartDataSet.drawFilledEnabled = true
            chartDataSet.drawHorizontalHighlightIndicatorEnabled = false
            chartDataSet.highlightEnabled = true
            chartDataSet.highlightColor = K.Colors.Brand.main
            chartDataSet.highlightLineWidth = 2
            chartDataSet.valueTextColor = K.Colors.Text.ternary
            
            // Setup Chart Data
            
            let data = LineChartData(dataSet: chartDataSet)
            data.setDrawValues(false)
            
            DispatchQueue.main.async {
                self.stockChartView.data = data
                completion(true)
            }
        }
    }
    
    //MARK: - Private methods
    
    private func setupUI() {
        self.backgroundColor = K.Colors.Background.secondary
        
        selectedBackgroundView = {
            let view = UIView.init()
            view.backgroundColor = .clear
            return view
        }()
    }
    
    private func setupLayout() {
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
