//
//  ViewController.swift
//  WKWebviewTest
//
//  Created by Mac on 5/22/20.
//  Copyright © 2020 Mac. All rights reserved.
//

// resources
// https://developer.apple.com/documentation/webkit/wkwebview
// https://developer.apple.com/documentation/webkit/wkwebviewconfiguration
// https://developer.apple.com/documentation/webkit/wkpreferences
// https://developer.apple.com/documentation/webkit/wkusercontentcontroller
// https://developer.apple.com/documentation/webkit/wkscriptmessagehandler
// https://developer.apple.com/documentation/webkit/wkuserscriptinjectiontime
// https://developer.apple.com/documentation/safariservices/creating_a_content_blocker
    // https://stackoverflow.com/questions/32119975/how-to-block-external-resources-to-load-on-a-wkwebview
// https://developer.apple.com/documentation/webkit/wkwebsitedatastore
// https://developer.apple.com/documentation/webkit/wkhttpcookiestore
// https://developer.apple.com/documentation/webkit/wkhttpcookiestoreobserver
// https://developer.apple.com/documentation/webkit/wkwebview/1415004-loadhtmlstring
// https://developer.apple.com/documentation/foundation/urlrequest
// https://developer.apple.com/documentation/safariservices/creating_a_content_blocker
// https://developer.apple.com/documentation/webkit/wkcontentruleliststore

import UIKit
import WebKit

class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    var webView: WKWebView!
    var webViewEnabled = false;
    
    var blockData = false;
    
    let CONTENT_RULE_LIST_NAME = "block_data"
    
    //MARK: Properties
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var text: UITextField!
    
    //MARK: Actions
    
    
    // options that are passed to localtunnel
    // strURL
    // strWindowName
    // strWindowFeatures
    // options - captcha or otherwise
    //      _httprequest options:
    //          method: POST | GET
    //          cookies: string cookies that need to be added in
    //          params: GET or POST params
    //          useragent: useragent to set for the session
    
    
    func open(){
        // CASE _clear_cookies
        self.clearCookies {
            // add in callback so that you can close the webview or notifiy that stuff is done
        }
        
        // CASE _httprequest
        
    }
    
    // JAVASCRIPT
    @IBAction func runHTML(_ sender: Any) {
        self.webView.evaluateJavaScript(self.text.text ?? "console.log(1+1);", completionHandler: self.javascriptDone)
    }
    func javascriptDone(response: Any?, error: Error?) {
        print("OUTPUT from running javascript %@ %@", response, error)
    }

    @IBAction func toggleVisibilityAction(_ sender: Any) {
        self.toggleVisibility()
    }
    
    func toggleVisibility() {
        if self.webView.isHidden {
            self.webView.isHidden = false
        } else {
            self.webView.isHidden = true
        }
    }
    
    
    
    @IBAction func toggleWebviewAction(_ sender: Any) {
        toggleWebview()
    }
    
    func toggleWebview() {
        if webViewEnabled {
            self.destroyWebview()
        } else {
            self.createWebview()
        }
    }
    
    @IBAction func printCookiesAction(_ sender: Any) {
        printCookies()
    }
    
    func printCookies() {
        self.webView.configuration.websiteDataStore.httpCookieStore.getAllCookies({cookies in
            for cookie in cookies {
                NSLog("Cookies are: %@", cookie)
            }
        })
    }
    
    
    
    @IBAction func clearCookiesAction(_ sender: Any) {
        clearCookies(completionHander: {})
    }
    
    // COOKIE BEHAVIOR SUMMARY WITH WKWEBVIEW
    // Cookies persist between app opens and closes. Cookies persist between device opens
    // That means these are being written to disk
    // Cookies are applicaiton specific. You can completely clear your cookies without
    // having to worry about clobbering anyone else's cookies
    
    func clearCookies(completionHander: @escaping () -> Void){
        self.webView.configuration.websiteDataStore.httpCookieStore.getAllCookies({cookies in
            for cookie in cookies {
                self.webView.configuration.websiteDataStore.httpCookieStore.delete(cookie, completionHandler: completionHander)
            }
        })
    }
    
    
    @IBAction func toggleBlockAction(_ sender: Any) {
        self.blockData = !self.blockData
    }
    
    @IBAction func getAction(_ sender: Any) {
        self.goToURL(urlString: self.text.text ?? "https://google.com")
    }
    
    func goToURL(urlString: String) {
        self.webView.load(self.createRequest(urlString: urlString, method: "GET"))
    }
    
    
    @IBAction func postBodyAction(_ sender: Any) {
        do {
            try self.postBody()
        } catch {
            NSLog("Something went wrong sending the post request")
        }
    }
    
    // Built using this: https://useyourloaf.com/blog/how-to-percent-encode-a-url-string/ and comparing
    // to a basic form post in flask
    private func urlEncodeString(_ queryArgString: String) -> String? {
        let unreserved = "*-._&= "
        let allowed = NSMutableCharacterSet.alphanumeric()
        allowed.addCharacters(in: unreserved)
        
        var encoded = queryArgString.addingPercentEncoding(withAllowedCharacters: allowed as CharacterSet)
        encoded = encoded?.replacingOccurrences(of: " ", with: "+")
        return encoded
    }
    
    private func urlEncodeParams(_ params: [String:String]) -> String? {
        var combinedArray: [String] = []
        for (key, val) in params {
            combinedArray.append("\(key)=\(val)")
        }
        
        let queryArgString = combinedArray.joined(separator: "&")
        return self.urlEncodeString(queryArgString)
    }
    
    private func convertToFormData(_ params: [String:String]) -> Data? {
        let urlEncodedString = self.urlEncodeParams(params)
        return urlEncodedString?.data(using: String.Encoding.utf8)
    }
    
    private func convertToJSONData(_ params: Any) -> Data? {
        do {
            return try JSONSerialization.data(withJSONObject: params)
        } catch {
            return nil
        }
    }
    
    private func createRequest(urlString: String, method: String, params: [String:String]? = nil, postType: String = "form") -> URLRequest {
        if method.lowercased() == "post" {
            let url = URL(string: urlString)!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            if postType.lowercased() == "form" {
                request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                if params != nil {
                    request.httpBody = self.convertToFormData(params!)
                }
            } else if postType.lowercased() == "json" {
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                if params != nil {
                    request.httpBody = self.convertToJSONData(params!)
                }
            }
            return request
        } else {
            var finalUrlString = urlString
            if params != nil {
                finalUrlString = "\(finalUrlString)?\(self.urlEncodeParams(params!) ?? "")"
            }
            
            let url = URL(string: finalUrlString)!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            return request
        }
    }
    
    private func jsonDumps(_ jsonObject: Any) -> String? {
        let data = self.convertToJSONData(jsonObject)
        if data == nil {
            return nil
        } else {
            return String(data: data!, encoding: .utf8)
        }
    }
    
    // by defaut URLRequst will add the appropriate headers and cookies when you make the request through self.webview.load
    // turns off cookie handling - request.httpShouldHandleCookies = false
    // replaces cookies with manually set cookies - request.addValue(..., forHTTPHeaderField: "Cookie")
    //      More generally, .addValue(..., forHTTPHeaderField) just overwrites the default the network stack would have set for the header
    // requests made through URLSession.shared.dataTask(with: request) instead of self.webview.load will not have the cookies
    // implicitly set on their requests. You can still manually set the header yourself
    func postBody() throws {
        let params = [
            "zip": "48211",
            "dob": "1990-12-01",
            "dobmonth": "12",
            "dobday": "01",
            "dobyear": "1990",
            "pan": "5077110084273410",
            "newPasswd": "Bowden",
            "newConfPasswd": "Bowden",
        ]
        
//        let request = self.createRequest(urlString: "https://www.connectebt.com/miebtclient/passwdResetAction.recip", method: "POST", params: params, postType: "form")
        let request = self.createRequest(urlString: "https://f3571841.ngrok.io/cms/alex_test_post", method: "POST", params: params, postType: "json")
        self.webView.load(request)
    }
    
    @IBAction func replaceHTMLAction(_ sender: Any) {
        self.replaceHTML(self.text.text ?? "<div>Hello, World!</div>")
    }
    
    private func replaceHTML(_ htmlString: String) {
        self.webView.loadHTMLString(htmlString, baseURL: self.webView.url)
    }
    
    func createWebview() {
        let webConfiguration = WKWebViewConfiguration()
        
        if (self.blockData) {
            WKContentRuleListStore.default()?.lookUpContentRuleList(forIdentifier: CONTENT_RULE_LIST_NAME, completionHandler: {contentRuleList, error in
                if contentRuleList != nil {
                    webConfiguration.userContentController.add(contentRuleList!)
                }
                self.createWebviewWithConfiguration(webConfiguration)
            })
            
        } else {
            self.createWebviewWithConfiguration(webConfiguration)
        }
    }
        
    func createWebviewWithConfiguration(_ webConfiguration: WKWebViewConfiguration) {
        self.webView = WKWebView(frame: .zero, configuration: webConfiguration)
        self.webView.uiDelegate = self
        self.webView.navigationDelegate = self
        self.webView.frame = CGRect(x:0, y:300, width:view.frame.width, height:view.frame.width)
        self.webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)
        
//        let request = self.createRequest(urlString: "https://www.connectebt.com/miebtclient/index.jsp", method: "GET")
        let params = [
            "cat": "1",
            "dog": "2",
            "fish": "3",
            "man": "Yes he is",
        ]
        let request = self.createRequest(urlString: "https://f3571841.ngrok.io/cms/alex_test_get", method: "GET", params: params)
        
        // Set the user agent
//        self.webView.customUserAgent = "this-is-so-fake"
        self.webView.load(request)
        self.webViewEnabled = true;
    }
    
    func destroyWebview() {
        self.webView.removeFromSuperview()
        self.webView = nil;
        webViewEnabled = false;
    }
    
    // https://developer.apple.com/documentation/safariservices/creating_a_content_blocker
    private func addBlockRules(_ completionHandler: @escaping (WKContentRuleList?, Error?) -> Void) {
        
        let blockRules: [[String: Any]] = [
            [
                "trigger": [
                    "url-filter": ".*",
                    "resource-type": ["image", "media", "popup", "style-sheet"],
                ],
                "action": [
                    "type": "block",
                ],
            ],
        ]
        let stringRules = self.jsonDumps(blockRules)
        WKContentRuleListStore.default()?.compileContentRuleList(forIdentifier: CONTENT_RULE_LIST_NAME, encodedContentRuleList:stringRules , completionHandler: completionHandler)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addBlockRules({rulesList, error in
            self.createWebview()
        })
    }
    
    //MARK: NavigationDelegate
    func webview(_ webview: WKWebView, _ didCommit: WKNavigation) {
        NSLog("in webviewDelegate:didCommit %@", didCommit)
    }
    
    func webView(_ webView: WKWebView,
                 didStartProvisionalNavigation navigation: WKNavigation!) {
        NSLog("in webviewDelegate:didStartProvisionalNavigation %@", navigation)
    }
    
    func webView(_ webView: WKWebView,
                          didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        
        NSLog("in webviewDelegate:didReceiveServerRedirectForProvisionalNavigation %@", navigation)
    }
    
    internal func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        NSLog("in webviewDelegate:challenge:CompletionHandeler %@", challenge)
        completionHandler(.performDefaultHandling, nil)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("in webviewDelegate:didFail %@ %@", navigation, error)
    }
    
    func webView(_ webView: WKWebView,
    didFailProvisionalNavigation navigation: WKNavigation!,
    withError error: Error) {
        print("in webviewDelegate:didFailProvisional %@ %@", navigation, error)
    }
    
    func webView(_ webView: WKWebView,
                 didFinish navigation: WKNavigation!) {
        NSLog("in webViewDelegate:DidFinish %@", navigation)
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        NSLog("in webViewDelegate:DidTerminate %@")
    }
    
    // This function can probably be used to detect redirects as well
    func webView(_ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

     print("in webViewDelegate:DecisionHandler %@ %@", navigationAction.request, decisionHandler)
        
        // always open in the same frame, don't open new ones
        if (navigationAction.targetFrame == nil) {
            webView.load(navigationAction.request);
            decisionHandler(WKNavigationActionPolicy.cancel);
        } else {
            decisionHandler(WKNavigationActionPolicy.allow);
        }
        
    }
    
    func webView(_ webView: WKWebView,
    decidePolicyFor navigationResponse: WKNavigationResponse,
    decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        print("in webViewDelegate:DecisionHandlerResponse %@ %@", navigationResponse.response, decisionHandler)
        decisionHandler(WKNavigationResponsePolicy.allow);
    }
    
    //MARK: WKUIDelegate
    func webView(_ webView: WKWebView,
    createWebViewWith configuration: WKWebViewConfiguration,
                  for navigationAction: WKNavigationAction,
                  windowFeatures: WKWindowFeatures) -> WKWebView? {
        NSLog("in WKUIDelegate: createWebviewWith %@ %@ %@", configuration, navigationAction, windowFeatures)
        // NOt sure that frame should just be the same as the other frame here
//        return WKWebView(frame: webView.frame, configuration: configuration);
        
        // Just load it in the original view not in a new view
        return nil;
    }
    
    // The three functions below are all designed so that you could pop up an alert handler from javascript.
    // IT NEVER DOES SO BY DEFAULT
    func webView(_ webView: WKWebView,
    runJavaScriptAlertPanelWithMessage message: String,
         initiatedByFrame frame: WKFrameInfo,
         completionHandler: @escaping () -> Void) {
             NSLog("in WKUIDelegate:runJavascriptAlertPanelWithMessage %@ %@", message, frame)
             completionHandler();
    }
    
    func webView(_ webView: WKWebView,
    runJavaScriptConfirmPanelWithMessage message: String,
         initiatedByFrame frame: WKFrameInfo,
         completionHandler: @escaping (Bool) -> Void) {
             NSLog("in WKUIDelegate:runJavaScriptConfirmPanelWithMessage %@ %@", message, frame)
        completionHandler(true);
    }
    
    func webView(_ webView: WKWebView,
    runJavaScriptTextInputPanelWithPrompt prompt: String,
              defaultText: String?,
         initiatedByFrame frame: WKFrameInfo,
         completionHandler: @escaping (String?) -> Void) {
        print("in WKUIDelegate:runJavaScriptTextInputPanelWithPrompt %@ %@ %@", prompt, defaultText ?? "no default", frame)
        completionHandler("yes");
        
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        NSLog("in WKUIDelegate:webViewDidClose")
    }

}

