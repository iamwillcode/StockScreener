import UIKit
import WebKit

class WebViewController: UIViewController {
    
    //MARK: - IBOutlets
    
    var webView: WKWebView!
    
    //MARK: - Public properties
    
    var url: URL!
    
    //MARK: - Lifecycle
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        assert(url != nil, "Bad URL")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        loadNewsPage()
        setupUI()
    }
    
    private func loadNewsPage() {
        let request = URLRequest(url: url)
        webView.load(request)
        print(url)
    }
    
    private func setupUI() {
       
    }
}

extension WebViewController: WKUIDelegate {}
