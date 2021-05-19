import UIKit
import Charts

final class StockChartCell: UITableViewCell {
    
    //MARK: - Public properties
    
    // Set data for the chart when ticker value was setted
    var ticker: String? {
        didSet {
            setData(period: chartPeriod[periodSegmentedControl.selectedSegmentIndex]) { (result) in
                self.dataIsSetted = result
            }
        }
    }
    
    lazy var stockChartView: ChartView = {
        let chartView = ChartView()
        chartView.xAxis.enabled = false
        chartView.xAxis.drawAxisLineEnabled = false
        chartView.xAxis.avoidFirstLastClippingEnabled = true
        chartView.minOffset = 10
        chartView.rightAxis.enabled = false
        chartView.leftAxis.enabled = false
        chartView.legend.enabled = false
        chartView.dragEnabled = true
        chartView.setScaleEnabled(false)
        chartView.noDataText = "There is no data for the chosen period"
        chartView.noDataFont = UIFont.systemFont(ofSize: 20, weight: .semibold)
        chartView.noDataTextColor = K.Colors.Text.ternary
        return chartView
    }()
    
    lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.hidesWhenStopped = true
        indicator.color = .black
        indicator.style = .large
        return indicator
    }()
    
    lazy var priceLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    lazy var dateLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    lazy var infoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.distribution = .equalCentering
        stackView.spacing = 5
        stackView.addArrangedSubview(priceLabel)
        stackView.addArrangedSubview(dateLabel)
        return stackView
    }()
    
    lazy var chartInfoView: UIView = {
        let view = UIView()
        view.addSubview(infoStackView)
        return view
    }()
    
    lazy var periodSegmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: chartPeriod)
        segmentedControl.selectedSegmentIndex = 2
        return segmentedControl
    }()
    
    //MARK: - Private properties
    
    private let stockManager = StockManager()
    private let formatter = StockFormatter()
    private let detailViewController = DetailViewController()
    
    private var chartPeriod = ["D", "W", "M", "3M", "6M", "Y"] // items of the periodSegmentedControl
    private var dataIsSetted = false {
        didSet {
            setupChartLoading()
        }
    }
    
    // MARK: - Lifecycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        stockChartView.delegate = self
        
        setupCell()
        setupChartLoading()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        stockChartView.delegate = self
        
        setupCell()
        setupChartLoading()
    }
    
    //MARK: - Public Methods
    
    func setData(period: String, completion: @escaping (Bool) -> Void) {
        guard let ticker = ticker else { return }
        
        dataIsSetted = false
        
        var entries = [ChartDataEntry]()
        
        stockManager.getChartData(for: ticker, period: period) {
            (prices, timestamps) in
            guard let ps = prices,
                  let ts = timestamps else {
                self.stockChartView.data = nil
                completion(true)
                return
            }
            
            // Convert two arrays into array of tuples
            let axisData = zip(ts, ps).map { ($0, $1) }
            
            // Initialize Chart Data Entries from axisData elements
            for (xAxisData, yAxisData) in axisData {
                let chartDataEntry = ChartDataEntry(x: xAxisData, y: yAxisData)
                entries.append(chartDataEntry)
            }
            
            // Setup the chart color by calculating a median of prices
            let median = ps.sorted(by: <)[ps.count / 2]
            
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
            chartDataSet.highlightColor = K.Colors.Brand.secondary
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
    
    // Set new data for the chart when period was changed
    @objc func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        setData(period: chartPeriod[index]) { (result) in
            self.dataIsSetted = result
        }
    }
    
    //MARK: - Private methods
    
    private func setupCell() {
        contentView.isUserInteractionEnabled = true
        
        self.addSubview(stockChartView)
        self.addSubview(activityIndicator)
        self.addSubview(chartInfoView)
        self.addSubview(periodSegmentedControl)
        
        periodSegmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged)
        
        setupUI()
        setupLayout()
    }
    
    private func setupUI() {
        // Self
        self.backgroundColor = K.Colors.Background.secondary
        
        // Labels
        priceLabel.textColor = K.Colors.Text.ternary
        dateLabel.textColor = K.Colors.Text.quaternary
        priceLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        dateLabel.font = UIFont.systemFont(ofSize: 18, weight: .light)
        
        // Period Segmented Control
        periodSegmentedControl.backgroundColor = K.Colors.Background.secondary
        periodSegmentedControl.selectedSegmentTintColor = K.Colors.Brand.secondary
        periodSegmentedControl.setTitleTextAttributes([.foregroundColor: K.Colors.Text.ternary], for: .normal)
        periodSegmentedControl.setTitleTextAttributes([.foregroundColor: K.Colors.Text.main], for: .selected)
        periodSegmentedControl.isHidden = true
        
        // Selection style of the cell
        selectedBackgroundView = {
            let view = UIView.init()
            view.backgroundColor = .clear
            return view
        }()
    }
    
    private func setupLayout() {
        // Self
        self.heightAnchor.constraint(greaterThanOrEqualTo: self.widthAnchor, multiplier: 0.7).isActive = true
        
        // Stock Chart View
        stockChartView.translatesAutoresizingMaskIntoConstraints = false
        stockChartView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        stockChartView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        stockChartView.topAnchor.constraint(equalTo: chartInfoView.bottomAnchor).isActive = true
        stockChartView.bottomAnchor.constraint(equalTo: periodSegmentedControl.topAnchor, constant: -5.0).isActive = true
        
        // Chart Info View
        chartInfoView.translatesAutoresizingMaskIntoConstraints = false
        chartInfoView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
        chartInfoView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        chartInfoView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        chartInfoView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        chartInfoView.bottomAnchor.constraint(equalTo: stockChartView.topAnchor).isActive = true
        
        // Info Stack View
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        infoStackView.trailingAnchor.constraint(equalTo: chartInfoView.trailingAnchor, constant: -20.0).isActive = true
        infoStackView.leadingAnchor.constraint(equalTo: chartInfoView.leadingAnchor, constant: 20.0).isActive = true
        infoStackView.topAnchor.constraint(equalTo: chartInfoView.topAnchor, constant: 5.0).isActive = true
        infoStackView.bottomAnchor.constraint(equalTo: chartInfoView.bottomAnchor, constant: -5.0).isActive = true
        
        // Period Segmented Control
        periodSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        periodSegmentedControl.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        periodSegmentedControl.widthAnchor.constraint(greaterThanOrEqualTo: self.widthAnchor, multiplier: 0.7).isActive = true
        periodSegmentedControl.topAnchor.constraint(equalTo: stockChartView.bottomAnchor, constant: 5.0).isActive = true
        periodSegmentedControl.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20.0).isActive = true
        
        // Activity Indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        activityIndicator.heightAnchor.constraint(equalToConstant: 50).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    private func setupChartLoading() {
        if !dataIsSetted {
            stockChartView.isHidden = true
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
            stockChartView.isHidden = false
            periodSegmentedControl.isHidden = false
        }
    }
}

//MARK: - Chart View Delegate

extension StockChartCell: ChartViewDelegate {
    /// Displays price and date of selected value on the Chart View
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let price = Double(highlight.y)
        let date = Double(highlight.x)
        
        priceLabel.text = formatter.formattedPrice(price)
        
        if periodSegmentedControl.selectedSegmentIndex == 0 {
            dateLabel.text = formatter.formattedDateAndTimeFromUnixTimestamp(date)
        } else {
            dateLabel.text = formatter.formattedDateFromUnixTimestamp(date)
        }
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        priceLabel.text = ""
        dateLabel.text = ""
    }
}
