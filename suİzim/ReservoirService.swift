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

struct IzmirBaraj: Codable {
    let BarajKuyuAdi: String
    let DolulukOrani: Double
    let MaksimumSuKapasitesi: Double
    let SuDurumu: Double
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
    private var listContinuation: CheckedContinuation<[ReservoirInfo], Never>? // Renamed from izmirContinuation
    
    // MARK: - Public API
    func fetchReservoirData(for city: City = .istanbul) async -> [ReservoirInfo] {
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
             // User requested to match izmirbaraj.com specific value (e.g. 8.75%)
             // This site likely uses a simple arithmetic mean of the percentages, not weighted by volume.
             guard let url = URL(string: "https://openapi.izmir.bel.tr/api/izsu/barajdurum") else { return (0.0, "") }
             do {
                 let (data, _) = try await URLSession.shared.data(from: url)
                 let dams = try JSONDecoder().decode([IzmirBaraj].self, from: data)
                 
                 guard !dams.isEmpty else { return (0.0, "") }
                 
                 // Simple Average Calculation
                 let totalPercentage = dams.reduce(0.0) { $0 + $1.DolulukOrani }
                 let simpleAvg = totalPercentage / Double(dams.count)
                 
                 return (simpleAvg, "Canlı Veri (İzmir)")
             } catch {
                 return (0.0, "")
             }
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
    private func fetchIstanbulDetails() async -> [ReservoirInfo] {
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
             
             self.listContinuation = continuation
             
             // Time out handled in webView didFinish + internal timeout
             DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
                 if self?.listContinuation != nil {
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
            continuation = nil // Ensure nil before resume
            c.resume(returning: nil)
        }
        
        if let lc = listContinuation {
            listContinuation = nil // Ensure nil before resume
            lc.resume(returning: [])
        }
    }
    
    // MARK: - Izmir Logic
    private func fetchIzmirData() async -> [ReservoirInfo] {
        // Official API found via Open Data Portal
        guard let url = URL(string: "https://openapi.izmir.bel.tr/api/izsu/barajdurum") else { return [] }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // Response is a JSON Array: [{"BarajKuyuAdi":"...", "DolulukOrani":1, ...}, ...]
            let dams = try JSONDecoder().decode([IzmirBaraj].self, from: data)
            
            return dams.map { item in
                ReservoirInfo(
                    name: item.BarajKuyuAdi,
                    occupancyRate: item.DolulukOrani,
                    city: .izmir
                )
            }
        } catch {
            print("Izmir API Error: \(error)")
            // Fallback to empty (or we could keep scraper as backup, but API is preferred)
            return []
        }
    }
    
    // MARK: - Bursa Logic
    private func fetchBursaData() async -> [ReservoirInfo] {
        guard let url = URL(string: "https://bapi.bursa.bel.tr/apigateway/bbbAcikVeri_Buski/baraj") else { 
            print("Bursa URL Error")
            return [] 
        }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            // Create a session that ignores SSL errors just for testing (if possible) or use default
            // Create a session that ignores SSL errors just for testing (if possible) or use default
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let bursaResponse = try JSONDecoder().decode(BursaResponse.self, from: data)
            
            var dams: [ReservoirInfo] = []
            for item in bursaResponse.sonuc {
                // Include all items, even "Geneli", to ensure we show data.
                // UI can filter if needed, or we use unique ID.
                dams.append(ReservoirInfo(
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
        
        // HTML'in tamamını alıp spesifik bir ID veya class aramak daha iyidir.
        // Ancak basit regex düzeltmesi şöyledir:
        // Sadece sayıya odaklanmak yerine, öncesinde veya sonrasında % işareti veya 'Doluluk' kelimesi arayın.
        
        return await scrapeWebsite(url: url) { text in
            // Örnek metin: "Genel Doluluk Oranı % 35,40"
            let pattern = #"%\s*(\d{1,2}[.,]\d{2})"# // % işareti, opsiyonel boşluk, sayı
            
            if let range = text.range(of: pattern, options: .regularExpression) {
                let matchString = String(text[range])
                // matchString "% 35,40" olabilir, buradan sadece sayıyı çekmeliyiz:
                let numberPattern = #"(\d{1,2}[.,]\d{2})"#
                if let numberRange = matchString.range(of: numberPattern, options: .regularExpression) {
                    let numberStr = String(matchString[numberRange]).replacingOccurrences(of: ",", with: ".")
                    return Double(numberStr)
                }
            }
            return nil
        }
    }
    
    @MainActor
    private func scrapeAnkaraData() async -> (Double, String)? {
        guard let url = URL(string: "https://www.aski.gov.tr/tr/Baraj.aspx") else { return nil }
        
        // Ankara verisi 'data-percent' attribute içinde saklanıyor
        return await scrapeWebsite(url: url, script: "document.body.innerHTML") { html in
            // Pattern 1: BarajOrani1 elementinden data-percent çek
            let pattern1 = #"id="BarajOrani1"[^>]*data-percent="(\d+(?:[.,]\d+)?)"#
            if let match = self.firstMatch(in: html, regex: pattern1) {
                let numberPart = match.replacingOccurrences(of: ",", with: ".")
                if let value = Double(numberPart) {
                    print("Ankara Pattern1 Match: \(value)")
                    return value
                }
            }
            
            // Pattern 2: Genel doluluk oranı için data-percent arama (herhangi bir yerde)
            let pattern2 = #"data-percent="(\d+(?:[.,]\d+)?)"#
            if let match = self.firstMatch(in: html, regex: pattern2) {
                let numberPart = match.replacingOccurrences(of: ",", with: ".")
                if let value = Double(numberPart) {
                    print("Ankara Pattern2 Match: \(value)")
                    return value
                }
            }
            
            // Pattern 3: %XX.XX formatında arama
            let pattern3 = #"%\s*(\d+(?:[.,]\d+)?)\s*"#
            if let match = self.firstMatch(in: html, regex: pattern3) {
                let numberPart = match.replacingOccurrences(of: ",", with: ".")
                if let value = Double(numberPart) {
                    print("Ankara Pattern3 Match: \(value)")
                    return value
                }
            }
            
            // Pattern 4: Doluluk Oranı: XX.XX şeklinde metin arama
            let pattern4 = #"(?:doluluk|oran)[^0-9]*(\d+(?:[.,]\d+)?)"#
            if let match = self.firstMatch(in: html, regex: pattern4) {
                let numberPart = match.replacingOccurrences(of: ",", with: ".")
                if let value = Double(numberPart) {
                    print("Ankara Pattern4 Match: \(value)")
                    return value
                }
            }
            
            print("Ankara: No pattern matched")
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
        // Implement Polling instead of hard wait
        // Start checking for content immediately and repeat every 0.5s for 5 seconds max
        checkForContent(in: webView, attempt: 0)
    }
    
    private func checkForContent(in webView: WKWebView, attempt: Int) {
        // Max 10 attempts (5 seconds)
        guard attempt < 10 else {
            // Give up and try to extract what we have
            finalizeExtraction(from: webView)
            return
        }
        
        // Lightweight check to see if body has substantial content
        let checkScript = "document.body.innerText.length"
        webView.evaluateJavaScript(checkScript) { [weak self] (result, error) in
            guard let length = result as? Int, length > 100 else {
                // Not ready, try again
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.checkForContent(in: webView, attempt: attempt + 1)
                }
                return
            }
            // Ready
            self?.finalizeExtraction(from: webView)
        }
    }
    
    private func finalizeExtraction(from webView: WKWebView) {
        guard let url = webView.url?.absoluteString else { return }
        
        // Dispatch based on URL/State
        if url.contains("iski.istanbul") {
             if self.continuation != nil {
                 self.extractData(from: webView) // General Rate
             } else if self.listContinuation != nil {
                 self.extractIstanbulDetails(from: webView) // Details List
             }
        } else {
            self.extractData(from: webView)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        cleanup()
    }
    
    // Tekil veri çekme (İstanbul/Ankara)
    private func extractData(from webView: WKWebView) {
        let isAnkara = webView.url?.absoluteString.contains("aski.gov.tr") ?? false
        
        // For Ankara, try multiple possible element IDs and also get data-percent attribute
        let script = isAnkara 
            ? """
            (function() {
                var result = {};
                // Try label elements
                var label1 = document.getElementById('LabelBarajOrani1');
                var label2 = document.getElementById('LabelBarajOrani');
                result.labelTotal = label1 ? label1.innerText : null;
                result.labelActive = label2 ? label2.innerText : null;
                
                // Try data-percent attribute on circle elements
                var circles = document.querySelectorAll('[data-percent]');
                result.dataPercents = [];
                circles.forEach(function(el) {
                    result.dataPercents.push(el.getAttribute('data-percent'));
                });
                
                // Try BarajOrani1 element
                var orani1 = document.getElementById('BarajOrani1');
                result.orani1Percent = orani1 ? orani1.getAttribute('data-percent') : null;
                
                // Get entire innerHTML for debugging (first 2000 chars)
                result.htmlSample = document.body.innerHTML.substring(0, 2000);
                
                return JSON.stringify(result);
            })()
            """
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
                    // Ankara uses complex JSON with multiple possible sources
                    print("Ankara Raw Response: \(resultString)")
                    
                    // Try 1: orani1Percent (data-percent attribute)
                    let pattern1 = #""orani1Percent"\s*:\s*"(\d+(?:[.,]\d+)?)""#
                    if let match = self?.firstMatch(in: resultString, regex: pattern1) {
                        let numberPart = match.replacingOccurrences(of: ",", with: ".")
                        value = Double(numberPart)
                        print("Ankara - Found orani1Percent: \(value ?? 0)")
                    }
                    
                    // Try 2: dataPercents array - first value
                    if value == nil {
                        let pattern2 = #""dataPercents"\s*:\s*\[\s*"(\d+(?:[.,]\d+)?)""#
                        if let match = self?.firstMatch(in: resultString, regex: pattern2) {
                            let numberPart = match.replacingOccurrences(of: ",", with: ".")
                            value = Double(numberPart)
                            print("Ankara - Found dataPercents[0]: \(value ?? 0)")
                        }
                    }
                    
                    // Try 3: labelTotal (LabelBarajOrani1)
                    if value == nil {
                        let pattern3 = #""labelTotal"\s*:\s*"(\d+(?:[.,]\d+)?)\s*%?""#
                        if let match = self?.firstMatch(in: resultString, regex: pattern3) {
                            let numberPart = match.replacingOccurrences(of: ",", with: ".")
                            value = Double(numberPart)
                            print("Ankara - Found labelTotal: \(value ?? 0)")
                        }
                    }
                    
                    if value == nil {
                        print("Ankara: All patterns failed")
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
    

    // İstanbul Detaylı Liste Verisi Çekme (Scraping)
    private func extractIstanbulDetails(from webView: WKWebView) {
        let script = "document.documentElement.outerHTML" // Search entire HTML
        
        webView.evaluateJavaScript(script) { [weak self] (result, error) in
            guard let html = result as? String, error == nil else {
                self?.cleanup()
                return
            }
            
            Task.detached {
                var dams: [ReservoirInfo] = []
                let damNames = ["Ömerli", "Darlık", "Elmalı", "Terkos", "Alibey", "Büyükçekmece", "Sazlıdere", "Istrancalar", "Kazandere", "Pabuçdere"]
                
                let lowerHtml = html.lowercased()
                
                for name in damNames {
                    let lowerName = name.lowercased()
                    if let rangeName = lowerHtml.range(of: lowerName) {
                         let start = rangeName.upperBound
                         let end = lowerHtml.index(start, offsetBy: 200, limitedBy: lowerHtml.endIndex) ?? lowerHtml.endIndex
                         let substring = lowerHtml[start..<end]
                         
                         let pattern = #"(\d{1,2}[.,]\d{2})"#
                         if let rangeVal = substring.range(of: pattern, options: .regularExpression) {
                             let valStr = String(substring[rangeVal]).replacingOccurrences(of: ",", with: ".")
                             if let val = Double(valStr) {
                                 if val <= 100.0 {
                                     dams.append(ReservoirInfo(name: name, occupancyRate: val, city: .istanbul))
                                 }
                             }
                         }
                    }
                }
                
                let uniqueDams = Array(Set(dams))
                
                await MainActor.run {
                    if let lc = self?.listContinuation {
                        self?.listContinuation = nil // Prevent double resume
                        lc.resume(returning: uniqueDams)
                    }
                    self?.cleanup()
                }
            }
        }
    }
}
