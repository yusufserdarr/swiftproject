import Foundation
import WebKit

struct IBBResponse: Codable {
    let result: IBBResult
}

struct IBBResult: Codable {
    let records: [IBBRecord]
}

struct IBBRecord: Codable {
    let DATE: String
    let GENERAL_DAM_OCCUPANCY_RATE: Double
}

struct BursaResponse: Codable {
    let sonuc: [BursaDam]
}

struct BursaDam: Codable {
    let barajAdi: String
    let dolulukOrani: Double
    let olcumTarihi: Int64?
}

@MainActor
class ReservoirService: NSObject, ObservableObject {
    // ... existing properties ...
    private let resourceId = "b68cbdb0-9bf5-474c-91c4-9256c07c4bdf"
    private let baseUrl = "https://data.ibb.gov.tr/api/3/action/datastore_search"
    private let cacheKey = "CachedReservoirData"
    
    // Scraper properties
    private var webView: WKWebView?
    private var continuation: CheckedContinuation<(Double, String)?, Never>?
    private var izmirContinuation: CheckedContinuation<[ReservoirStatus], Never>?
    
    // MARK: - Public API
    func fetchReservoirData(for city: City = .istanbul) async -> [ReservoirStatus] {
        switch city {
        case .istanbul:
            // return [] // API does not provide individual dams
            return await fetchIstanbulDetails()
        case .ankara:
            return [] // ASKİ individual data not yet implemented
        case .izmir:
            return await fetchIzmirData()
        case .bursa:
            return await fetchBursaData()
        }
    }
    
    func getGeneralOccupancyRate(for city: City = .istanbul) async -> (rate: Double, date: String) {
        switch city {
        case .istanbul:
            if let apiResult = await fetchIstanbulGeneralRate() {
                return apiResult
            }
            return (0.0, "")
        case .ankara:
            if let scraped = await scrapeAnkaraData() {
                return scraped
            }
            return (0.0, "")
        case .izmir:
             // Calculate from individual dams if scraped general is not available
             // But usually for Izmir we get individual dams.
             // We can calculate avg or sum if needed.
             // Let's use the average of valid dams for now or 0 if empty.
            let dams = await fetchIzmirData()
            guard !dams.isEmpty else { return (0.0, "") }
            
            // Weighted average would be better if we had capacity, but for now simple average or 
            // if we can find a general rate in the CSV or scraping logic.
             let totalRate = dams.reduce(0.0) { $0 + $1.occupancyRate }
             let avg = totalRate / Double(dams.count)
             return (avg, "Canlı Veri (İzmir)")
        case .bursa:
            let dams = await fetchBursaData()
            // Find "Bursa Geneli" if exists or average
            if let general = dams.first(where: { $0.name.contains("Geneli") }) {
                return (general.occupancyRate, "Canlı Veri (Bursa)")
            }
            // Fallback average
            guard !dams.isEmpty else { return (0.0, "") }
            let total = dams.reduce(0.0) { $0 + $1.occupancyRate }
            return (total / Double(dams.count), "Canlı Veri (Bursa)")
        }
    }
    
    // MARK: - Istanbul Logic
    private func fetchIstanbulGeneralRate() async -> (rate: Double, date: String)? {
        // 1. Try Scraping General Rate
        if let scrapedData = await scrapeIstanbulLiveData() {
            return scrapedData
        }
        return nil
    }
    
    // NEW: Fetch Individual Dam Data for Istanbul
    private func fetchIstanbulDetails() async -> [ReservoirStatus] {
         await MainActor.run { cleanup() } 
         
         guard let url = URL(string: "https://iski.istanbul/baraj-doluluk/") else { return [] }
         
         return await withCheckedContinuation { continuation in
             let config = WKWebViewConfiguration()
             let webView = WKWebView(frame: .zero, configuration: config)
             webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
             
             self.webView = webView
             webView.navigationDelegate = self
             
             let request = URLRequest(url: url)
             webView.load(request)
             
             // We reuse the 'izmirContinuation' type for list of dams, 
             // or we can add a new one. Since they are same type [ReservoirStatus], we can reuse.
             // But to be clean/safe against race conditions, we should probably be careful.
             // Since we cleanup() before, reusing is fine.
             self.izmirContinuation = continuation
             
             DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
                 if self?.izmirContinuation != nil {
                     print("Istanbul Detail Timeout")
                     self?.cleanup()
                 }
             }
         }
    }
    
    private func cleanup() {
        webView?.stopLoading()
        webView?.navigationDelegate = nil
        webView = nil
        
        // CRITICAL FIX: Resume any pending continuations so tasks don't hang/leak
        if let c = continuation {
            c.resume(returning: nil)
        }
        continuation = nil
        
        if let ic = izmirContinuation {
            ic.resume(returning: [])
        }
        izmirContinuation = nil
    }
    
    // MARK: - Izmir Logic
    private func fetchIzmirData() async -> [ReservoirStatus] {
        await MainActor.run { cleanup() } 
        
        // Create URL - using base URL to let WebView handle redirects naturally
        guard let url = URL(string: "https://www.izsu.gov.tr/tr/Barajlar/BarajSuDolulukOranlari") else { return [] }
        
        return await withCheckedContinuation { continuation in
            // Create WebView on Main Thread
            let config = WKWebViewConfiguration()
            let webView = WKWebView(frame: .zero, configuration: config)
            webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
            
            self.webView = webView
            webView.navigationDelegate = self
            
            let request = URLRequest(url: url)
            webView.load(request)
            
            self.izmirContinuation = continuation
            
            // Timeout safety
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
                // Only act if this specific continuation is still active
                if self?.izmirContinuation != nil {
                    print("Izmir Timeout - Resume returning empty")
                    self?.cleanup() // This will resume with []
                }
            }
        }
    }
    
    // MARK: - Bursa Logic
    private func fetchBursaData() async -> [ReservoirStatus] {
        guard let url = URL(string: "https://bapi.bursa.bel.tr/apigateway/bbbAcikVeri_Buski/baraj") else { 
            print("Bursa URL Error")
            return [] 
        }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            // Create a session that ignores SSL errors just for testing (if possible) or use default
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                // print("Bursa API Code: \(httpResponse.statusCode)")
            }
            
            // Debug raw data
            if let str = String(data: data, encoding: .utf8) {
                // print("Bursa Raw Response: \(str)")
            }

            let bursaResponse = try JSONDecoder().decode(BursaResponse.self, from: data)
            
            var dams: [ReservoirStatus] = []
            for item in bursaResponse.sonuc {
                // Include all items, even "Geneli", to ensure we show data.
                // UI can filter if needed, or we use unique ID.
                dams.append(ReservoirStatus(
                    name: item.barajAdi,
                    occupancyRate: item.dolulukOrani,
                    city: .bursa
                ))
            }
            return dams
        } catch {
            print("Bursa API Error: \(error)")
            return []
        }
    }
    
    // MARK: - Web Scraping (Shared Single Value Logic)
    private func scrapeWebsite(url: URL, script: String = "document.body.innerText", extractor: @escaping (String) -> Double?) async -> (Double, String)? {
        cleanup() 
        
        return await withCheckedContinuation { continuation in
            let config = WKWebViewConfiguration()
            let webView = WKWebView(frame: .zero, configuration: config)
            webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
            
            self.webView = webView
            self.continuation = continuation
            
            webView.navigationDelegate = self
            
            let request = URLRequest(url: url)
            webView.load(request)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [weak self] in
                if self?.continuation != nil {
                    print("Shared Scraper Timeout")
                    self?.cleanup() // This will resume with nil
                }
            }
        }
    }
    
    private func scrapeIstanbulLiveData() async -> (Double, String)? {
        guard let url = URL(string: "https://iski.istanbul/baraj-doluluk/") else { return nil }
        return await scrapeWebsite(url: url) { text in
            let pattern = #"(\d{1,2}[.,]\d{2})"#
            if let range = text.range(of: pattern, options: .regularExpression) {
                let match = String(text[range]).replacingOccurrences(of: ",", with: ".")
                return Double(match)
            }
            return nil
        }
    }
    
    @MainActor
    private func scrapeAnkaraData() async -> (Double, String)? {
        guard let url = URL(string: "https://www.aski.gov.tr/tr/Baraj.aspx") else { return nil }
        
        // Ankara verisi 'data-percent' attribute içinde saklanıyor. innerText yerine innerHTML bakalım.
        return await scrapeWebsite(url: url, script: "document.body.innerHTML") { html in
            // Search for: data-percent="13.95"
            // specifically for BarajOrani1 which seems to be the main one
            let pattern = #"id="BarajOrani1".*?data-percent="(\d{1,2}[.,]\d{2})""#
            
            if html.range(of: pattern, options: .regularExpression) != nil {
               // Extract the capture group manually since Swift Regex finding is text based
               // Pattern matching in strings for capture groups needs simpler approach if we just want the number
            }
            
            // Simpler Regex matching
            // Look for `data-percent="XX.XX"` followed by `BarajOrani1` check or generic.
            // Let's rely on the specific ID `BarajOrani1` proximity.
            
            // Regex: id="BarajOrani1" ... (anything) ... data-percent="13.95"
            // OR: data-percent="13.95" ... id="BarajOrani1" 
            // The HTML was: <div id="BarajOrani1" class="..." data-percent="13.95" ...>
            
            let idPattern = #"id="BarajOrani1"[^>]*data-percent="(\d+(?:[.,]\d+)?)""#
            if let match = self.firstMatch(in: html, regex: idPattern) {
                 let numberPart = match.replacingOccurrences(of: ",", with: ".")
                 return Double(numberPart)
            }
            
            return nil
        }
    }
    
    private func firstMatch(in text: String, regex: String) -> String? {
        do {
            let re = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results = re.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            if let first = results.first, first.numberOfRanges > 1 {
                return nsString.substring(with: first.range(at: 1))
            }
        } catch {
            print("Regex Error: \(error)")
        }
        return nil
    }
}

extension ReservoirService: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let url = webView.url?.absoluteString else { return }
            
            if url.contains("izsu.gov.tr") {
                self?.extractIzmirData(from: webView)
            } else if url.contains("iski.istanbul") {
                 // Determine if we are scraping general rate or details
                 // We can distinguish by checkin which continuation is active
                 if self?.continuation != nil {
                     self?.extractData(from: webView) // General Rate
                 } else if self?.izmirContinuation != nil {
                     self?.extractIstanbulDetails(from: webView) // Details List
                 }
            } else {
                self?.extractData(from: webView)
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // Hata durumunda bekleyen tüm işlemleri sonlandır
        continuation?.resume(returning: nil)
        izmirContinuation?.resume(returning: [])
        cleanup()
    }
    
    // Tekil veri çekme (İstanbul/Ankara)
    private func extractData(from webView: WKWebView) {
        let isAnkara = webView.url?.absoluteString.contains("aski.gov.tr") ?? false
        // For Ankara, fetch the specific Element IDs directly as JSON
        let script = isAnkara 
            ? "JSON.stringify({ total: document.getElementById('LabelBarajOrani1')?.innerText, active: document.getElementById('LabelBarajOrani')?.innerText })" 
            : "document.body.innerText"
        
        webView.evaluateJavaScript(script) { [weak self] (result, error) in
            guard let resultString = result as? String, error == nil, let url = webView.url?.absoluteString else {
                // Fail safe
                if let c = self?.continuation {
                    self?.continuation = nil
                    c.resume(returning: nil)
                }
                self?.cleanup()
                return
            }
            
            Task.detached {
                var value: Double?
                let date = Date().formatted(date: .numeric, time: .omitted)
                
                if url.contains("iski.istanbul") {
                    // Istanbul uses innerText -> resultString is plain text
                    let pattern = #"(\d{1,2}[.,]\d{2})"#
                    if let range = resultString.range(of: pattern, options: .regularExpression) {
                        let match = String(resultString[range]).replacingOccurrences(of: ",", with: ".")
                        value = Double(match)
                    }
                } else if url.contains("aski.gov.tr") {
                    // Ankara uses JSON -> resultString is JSON
                    // Parse JSON manually or with regex
                    // resultString: {"total":"13.05 %","active":"1.66 %"}
                    
                    // Regex to find "total":"13.05 %"
                    let pattern = #""total":"\s*(\d+[.,]?\d*)\s*%"#
                    if let range = resultString.range(of: pattern, options: .regularExpression) {
                         let matchSub = String(resultString[range])
                         let numberPattern = #"(\d+(?:[.,]\d+)?)"#
                         if let numRange = matchSub.range(of: numberPattern, options: .regularExpression) {
                             let numberPart = String(matchSub[numRange]).replacingOccurrences(of: ",", with: ".")
                             value = Double(numberPart)
                         }
                    } else {
                         print("Ankara JSON Parse Failed: \(resultString)")
                    }
                }
                
                let finalValue = value
                await MainActor.run {
                    // Safe Resume Pattern:
                    if let c = self?.continuation {
                        self?.continuation = nil // Critical: Prevent double resume in cleanup()
                        
                        if let v = finalValue {
                            c.resume(returning: (v, "Canlı Veri (\(date))"))
                        } else {
                            c.resume(returning: nil)
                        }
                    }
                    self?.cleanup()
                }
            }
        }
    }
    
    // İzmir Liste Verisi Çekme
    private func extractIzmirData(from webView: WKWebView) {
        let script = "document.body.innerText"
        webView.evaluateJavaScript(script) { [weak self] (result, error) in
            guard let text = result as? String, error == nil else {
                if let ic = self?.izmirContinuation {
                    self?.izmirContinuation = nil
                    ic.resume(returning: [])
                }
                self?.cleanup()
                return
            }
            
            // Offload parsing to background
            Task.detached {
                var dams: [ReservoirStatus] = []
                let damNames = ["Tahtalı", "Balçova", "Gördes", "Ürkmez", "Güzelhisar", "Alaçatı"]
                
                let lowerText = text.lowercased()
                
                for name in damNames {
                    let lowerName = name.lowercased()
                    if let rangeName = lowerText.range(of: lowerName) {
                        let subtitle = lowerText[rangeName.upperBound...]
                        let searchArea = String(subtitle.prefix(150))
                        
                        let pattern = #"(\d{1,2}[.,]\d{2})"#
                        if let rangeRate = searchArea.range(of: pattern, options: .regularExpression) {
                            let match = String(searchArea[rangeRate]).replacingOccurrences(of: ",", with: ".")
                            if let rate = Double(match) {
                                let displayName = name.capitalized + " Barajı"
                                dams.append(ReservoirStatus(name: displayName, occupancyRate: rate, city: .izmir))
                            }
                        }
                    }
                }
                
                let finalDams = dams
                await MainActor.run {
                    if let ic = self?.izmirContinuation {
                        self?.izmirContinuation = nil // Critical: Prevent double resume
                        ic.resume(returning: finalDams)
                    }
                    self?.cleanup()
                }
            }
        }
    }
    // İstanbul Detaylı Liste Verisi Çekme (Scraping)
    private func extractIstanbulDetails(from webView: WKWebView) {
        let script = "document.body.innerText" // Charts often expose data in accessibility text or we can try innerHTML
        // Better: document.documentElement.outerHTML to catch scripts
        let htmlScript = "document.documentElement.outerHTML"
        
        webView.evaluateJavaScript(htmlScript) { [weak self] (result, error) in
            guard let html = result as? String, error == nil else {
                self?.cleanup()
                return
            }
            
            Task.detached {
                var dams: [ReservoirStatus] = []
                let damNames = ["Ömerli", "Darlık", "Elmalı", "Terkos", "Alibey", "Büyükçekmece", "Sazlıdere", "Istrancalar", "Kazandere", "Pabuçdere"]
                
                // Strategy: Search for Name ... number pattern
                // OR search for highcharts data series if available.
                // Simple text fallback first:
                // "Ömerli % 85,12"
                
                // Let's try to match: Name followed nearby by a percentage-like number
                // Regex: (Name) ... many chars ... (\d+[,.]\d+)
                // This is risky. 
                
                // Alternative: Look for specific IDs or chart labels.
                
                // Let's try simple text regex closer to what we see on screen
                let lowerHtml = html.lowercased()
                
                for name in damNames {
                    let lowerName = name.lowercased()
                    // Find name
                    if let rangeName = lowerHtml.range(of: lowerName) {
                         // Search forward 200 chars for a number
                         let start = rangeName.upperBound
                         let end = lowerHtml.index(start, offsetBy: 200, limitedBy: lowerHtml.endIndex) ?? lowerHtml.endIndex
                         let substring = lowerHtml[start..<end]
                         
                         // Look for: 85,45 or 85.45
                         let pattern = #"(\d{1,2}[.,]\d{2})"#
                         if let rangeVal = substring.range(of: pattern, options: .regularExpression) {
                             let valStr = String(substring[rangeVal]).replacingOccurrences(of: ",", with: ".")
                             if let val = Double(valStr) {
                                 // Basic sanity check: occupancy is 0-100
                                 if val <= 100.0 {
                                     dams.append(ReservoirStatus(name: name, occupancyRate: val, city: .istanbul))
                                 }
                             }
                         }
                    }
                }
                
                // Deduplicate?
                // Just take unique names
                let uniqueDams = Array(Set(dams))
                
                if uniqueDams.isEmpty {
                     print("Izmir/Istanbul Scraper Failed. Content Preview: \(html.prefix(500))")
                } else {
                     print("Izmir/Istanbul Scraper Success. Found: \(uniqueDams.count) items.")
                }
                
                await MainActor.run {
                    if let ic = self?.izmirContinuation {
                        self?.izmirContinuation = nil
                        ic.resume(returning: uniqueDams)
                    }
                    self?.cleanup()
                }
            }
        }
    }
}
