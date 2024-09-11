//
//  SingleStock.swift
//  webtech
//
//  Created by Reem Badami on 27/04/24.
//

import Foundation
import SwiftyJSON
import SwiftUI
import Alamofire
import WebKit


struct Profile: Codable {
    let name: String
    let logo: String
    let ipo : String
    let finnhubIndustry: String
    let weburl: String
    
    static let empty = Profile(name:"",logo: "", ipo:"", finnhubIndustry:"", weburl: "")
}

struct Sentiment: Codable {
    let positiveMsprSum: Double
    let negativeMsprSum, totalMsprSum: Double
    let positiveChangeSum, negativeChangeSum, totalChangeSum: Double
}


struct SingleStock: View {
    let ticker: String
    @State private var quote: Quote?
    @State var profile: Profile = Profile.empty
    @Binding var portfolioItems: [portfolioItem]
    @State var loading = true
    @State var iconFill = false
    @Binding var cashBalance: Double
    var watchListItems: [watchListItem]
    @State private var showToast = false
    @State private var message = ""
    
    //    var isFavorite: Bool{
    //        return checkIfInWatchlist(ticker: ticker)
    //    }
    
    //    var color: String {
    //        if let quote = quote {
    //            return quote.d > 0 ? "198754" : (quote.dp < 0 ? "#FF0000" : "#808080")
    //        } else {
    //            return "#000000"
    //        }
    //    }
    
    
    
    
    var body: some View {
        VStack{
            
            if loading {
                ProgressView("Fetching Data...")
            }else{
                ScrollView {
                    VStack{
                        VStack{
                            HStack {
                                
                                if let quote = quote {
                                    
                                    VStack {
                                        
                                        HStack{
                                            Text(profile.name).foregroundStyle(Color(.gray)).font(.callout).padding(10)
                                            Spacer()
                                            AsyncImage(url: URL(string: profile.logo)){ phase in
                                                if let image = phase.image {
                                                    image
                                                        .resizable()
                                                        .frame(width: 50, height: 50)
                                                        .clipShape(.rect(cornerRadius: 15))
                                                }
                                            }
                                            .padding(.trailing, 15)
                                        }
                                        
                                        HStack{ Text("$\(String(format: "%.2f", quote.c))  ")
                                                .font(.title)
                                                .fontWeight(.bold)
                                                .padding(.leading, 10)
                                            
                                            
                                            switch quote.d {
                                            case let x where x > 0:
                                                Image(systemName: "arrow.up.right").foregroundColor(.green)
                                            case let x where x < 0:
                                                Image(systemName: "arrow.down.right").foregroundColor(.red)
                                            default:
                                                Image(systemName: "minus").foregroundColor(.gray)
                                            }
                                            
                                            
                                            Text("$\(String(format: "%.2f", quote.d)) (\(String(format: "%.2f", quote.dp))%)").font(.title2).foregroundColor(quote.d > 0 ? .green : (quote.d < 0 ? .red : .gray))
                                            
                                            Spacer()
                                        }
                                        
                                        Spacer()
                                    }.padding(.leading, 10)
                                    
                                }
                                
                                
                            }.navigationTitle(ticker).toolbar{
                                ToolbarItem(placement: .navigationBarTrailing)
                                {
                                    Button {
                                        toggleFavorite()
                                    }
                                label: { Image(systemName: iconFill ? "plus.circle.fill" : "plus.circle").resizable().frame(width: 24, height: 24).background(Circle().stroke(Color.blue, lineWidth: 2)).foregroundColor(.blue)
                                    
                                }
                                }
                            }
                            
                            
                            
                            TabView {
                                hourlyChartView(ticker: ticker, quote: quote)
                                    .tabItem {
                                        Label("Hourly", systemImage: "chart.xyaxis.line")
                                    }
                                historicalChartView(ticker: ticker)
                                    .tabItem {
                                        Label("Historical", systemImage: "clock.fill")
                                    }
                            }.frame(height: 500)
                            
                            stockPortfolioView(profile: $profile, portfolioItems: $portfolioItems, ticker: ticker, quote: quote, cashBalance: $cashBalance)
                            
                            statsAndInsightsView(ticker: ticker, quote: quote, profile: profile, portfolioItems: $portfolioItems, cashBalance: $cashBalance, watchListItems: watchListItems)
                            
                            recoChartView(ticker: ticker).frame(minHeight: 450)
                            
                            surpriseChartView(ticker: ticker).frame(minHeight: 450)
                            
                            NewsSection(ticker: ticker)
                            
                        }
                        
                    }
                    
                }.overlay(
                    Toast(message:message, isShowing: $showToast)
                    )
            }
        }.task {
            self.iconFill = isFavorite()
            await fetchData()
        }
        
    }
    
    func fetchData() async {
        do {
            await fetchQuote()
            await fetchProfileData()
            loading = false
        }
        catch{
            print(error)
        }
    }
    
    
    func fetchQuote() async {
        Task {
            do {
                let quote = try await fetchQuoteData(ticker: ticker)
                self.quote = quote
            } catch {
                print("Error fetching quote: \(error)")
            }
        }
    }
    
    func fetchProfileData() async {
        let urlString = "http://localhost:8080/api/profile/\(ticker)"
        AF.request(urlString).validate().responseDecodable(of: Profile.self) { response in
            switch response.result {
            case .success(let profile):
                DispatchQueue.main.async{
                    self.profile = profile
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    //    func checkIfInWatchlist(ticker: String) -> Bool {
    //        for item in watchListItems {
    //            if item.Ticker == ticker {
    //                return true
    //            }
    //        }
    //        return false
    //    }
    
    func isFavorite() -> Bool {
        return watchListItems.contains { $0.Ticker == ticker }
    }
    
    func toggleFavorite() {
        iconFill.toggle()
        if isFavorite() {
            deleteFavourite(ticker: ticker)
            self.message = "Removing \(ticker) from Favorites"
            self.showToast=true
        } else {
            addFavourite(ticker: ticker, name: profile.name)
            self.message = "Adding \(ticker) to Favorites"
            self.showToast=true
        }
    }
    
    func deleteFavourite(ticker: String) {
        let urlString = "http://localhost:8080/api/watchlist/"+ticker;
        _ = AF.request(urlString, method:.delete).response { response in
            switch response.result {
            case .success(_):
                print("favourite item deleted successfully");
            case .failure(let error):
                print("Failed to delte favourites item: \(error)");
            }
        }
    }
    
    func addFavourite(ticker: String, name: String) {
        let parameters: [String: String] = [
            "ticker":ticker,
            "name":name
        ]
        
        let urlString = "http://localhost:8080/api/watchlist/";
        _ = AF.request(urlString, method:.post, parameters:parameters, encoding:
                        JSONEncoding.default).response { response in
            switch response.result {
            case .success(_):
                print("favourite item added successfully");
            case .failure(let error):
                print("Failed to add favourites item: \(error)");
            }
        }
    }
    
}



struct hourlyChartView: View {
    let ticker: String
    let quote: Quote?
    
    var color: String {
        if let quote = quote{
            return quote.d > 0 ? "#198754" : (quote.d < 0 ? "#FF0000" : "#808080")
        }
        else{
            return "#000000"
        }
    }
    
    var body: some View {
        VStack{
            
            
            WebView(htmlString: """
                   <html>
                   <head>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                   <style>
                               #container {
                                 max-width: 400px;
                                 max-height: 490px;
                                 width: 100%; /* Ensures the container takes up the available width */
                                 height: auto; /* Automatically adjusts the height to maintain aspect ratio */
                               }
                             </style>
                   </head>
                   <body>
                   <div id="container"></div>
                   <script>
                   const fetchSingleDayStock = async (ticker) => {
                     try {
                       const currQuote = await fetch(`https://csci522-assignment3.wl.r.appspot.com/api/quote/${ticker}`);
                       const currQuoteJson = await currQuote.json();
                       console.log(currQuoteJson);
                   
                       let currentDate = new Date(currQuoteJson.response.t * 1000);
                       let oneDayAgo = new Date(currentDate.getTime() - 1 * 24 * 60 * 60 * 1000);
                       
                       const formatDate = (date) => {
                         const year = date.getFullYear();
                         const month = String(date.getMonth() + 1).padStart(2, "0");
                         const day = String(date.getDate()).padStart(2, "0");
                         return `${year}-${month}-${day}`;
                       };
                   
                       const formattedCurrentDate = formatDate(currentDate);
                       const formattedOneDayAgo = formatDate(oneDayAgo);
                       
                       const response = await fetch(`https://csci522-assignment3.wl.r.appspot.com/api/historical/${ticker}/${formattedOneDayAgo}/${formattedCurrentDate}`);
                       const resJson = await response.json();
                       return resJson;
                     } catch (error) {
                       console.error('Error fetching data:', error);
                       throw error; // Rethrow the error to be caught by the caller
                     }
                   };
                   
                   fetchSingleDayStock("\(ticker)").then(data => {
                     // Work with the parsed JSON data
                     let mappedData = data.response.results.map((item) => [item.t, item.o]);
                     
                     let options = {
                       chart: {
                         type: "line",
                         backgroundColor: "#ffffff",
                       },
                       title: {
                         text: `\(ticker) Hourly Price Variation`,
                         style: {
                                     color: '#918f8e',
                                 }
                       },
                       legend: {
                         enabled: false,
                       },
                       xAxis: {
                         type: "datetime",
                         labels: {
                           format: "{value:%H:%M}",
                         },
                         title: false,
                       },
                       yAxis: {
                         opposite: true,
                         title: false,
                       },
                       plotOptions: {
                         series: {
                           marker: {
                             enabled: false,
                             states: {
                               hover: {
                                 enabled: false,
                               },
                             },
                           },
                         },
                       },
                       series: [
                         {
                           data: mappedData,
                           color: "\(color)",
                         },
                       ],
                     };
                     
                     Highcharts.chart('container', options);
                   }).catch(error => {
                     // Handle any errors that might occur during fetching, processing, or chart rendering
                     console.error('Error:', error);
                   });
                   
                   </script>
                   <script src="https://code.highcharts.com/highcharts.js"></script>
                   <script src="https://code.highcharts.com/modules/exporting.js"></script>
                   <script src="https://code.highcharts.com/modules/export-data.js"></script>
                   <script src="https://code.highcharts.com/modules/accessibility.js"></script>
                   </body>
                   </html>
                   """)
        }
    }
}

struct WebView: UIViewRepresentable {
    let htmlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlString, baseURL: nil)
    }
}



struct historicalChartView: View {
    
    let ticker: String
    
    
    var body: some View {
        VStack{
            
            
            WebView(htmlString: """
    <!DOCTYPE html>
                        <html>
                            <head>
                             <meta name="viewport" content="width=device-width, initial-scale=0.9, maximum-scale=.9, user-scalable=no">
            <style>
                body{
                display:flex;
                justify-content:center;
                }
                #container {
                  max-width: 400px;
                  max-height: 490px;
                  width: 100%; /* Ensures the container takes up the available width */
                  height: auto; /* Automatically adjusts the height to maintain aspect ratio */
                }
              </style>
                            </head>
    
                    <body>
                        
                    <div id="container"></div>
                    <script src="https://code.highcharts.com/stock/highstock.js"></script>
                    <script src="https://code.highcharts.com/stock/modules/drag-panes.js"></script>
                    <script src="https://code.highcharts.com/stock/modules/exporting.js"></script>
                    <script src="https://code.highcharts.com/stock/indicators/indicators.js"></script>
                    <script src="https://code.highcharts.com/stock/indicators/volume-by-price.js"></script>
                    <!-- <script src="https://code.highcharts.com/modules/accessibility.js"></script> -->
                    <script>
                        const groupingUnits = [
                        ["week", [1]],
                        ["month", [1, 2, 3, 4, 6]],
                      ];
                        let fetchChartData = async ()=>{
                            const response = await fetch('https://csci522-assignment3.wl.r.appspot.com/api/historical/\(ticker)');
                            const chartData = await response.json();
                            let data = chartData.response.results;
                            let arr1 = [];
                            let arr2 = [];
                            for (let i = 0; i < data.length; i += 1) {
                            arr1.push([
                                data[i].t, // the date
                                data[i].o, // open
                                data[i].h, // high
                                data[i].l, // low
                                data[i].c, // close
                            ]);
    
                            arr2.push([
                                data[i].t, // the date
                                data[i].v, // the volume
                            ]);
                            }
                            return {
                                ohlc: arr1,
                                volume: arr2
                            };
                            }
                        let data = fetchChartData().then(data => {
                            console.log(data);
                            let options = {
                                chart: {
                                    height: 500,
                                    backgroundColor: "#ffffff",
                                },
                                rangeSelector: {
                                    allButtonsEnabled: true,
                                    enabled: true,
                                    selected: 2,
                                },
                                title: {
                                    text: `\(ticker) Historical`,
                                },
                                subtitle: {
                                    text: "With SMA and Volume by Price technical indicators",
                                },
                                navigator: {
                                    enabled: true,
                                },
                                scrollbar: {
                                    enabled: true,
                                },
                                credits: {
                                    enabled: false,
                                },
                                xAxis: {
                                    type: "datetime",
                                    title: false,
                                    ordinal: true,
                                },
                                yAxis: [
                                    {
                                        opposite: true,
                                        startOnTick: false,
                                        endOnTick: false,
                                        labels: {
                                            align: "right",
                                            x: -3,
                                        },
                                        title: {
                                            text: "OHLC",
                                        },
                                        height: "60%",
                                        lineWidth: 2,
                                        resize: {
                                            enabled: true,
                                        },
                                    },
                                    {
                                        opposite: true,
                                        labels: {
                                            align: "right",
                                            x: -3,
                                        },
                                        title: {
                                            text: "Volume",
                                        },
                                        top: "65%",
                                        height: "35%",
                                        offset: 0,
                                        lineWidth: 2,
                                    },
                                ],
                                
                                tooltip: {
                                    split: true,
                                },
                                
                                plotOptions: {
                                    series: {
                                        dataGrouping: {
                                            units: groupingUnits,
                                        },
                                        marker: {
                                            enabled: false,
                                            states: {
                                                hover: {
                                                    enabled: false,
                                                },
                                            },
                                        },
                                    },
                                },
                                
                                series: [
                                    {
                                        showInLegend: false,
                                        type: "candlestick",
                                        name: `\(ticker)`,
                                        id: "aapl",
                                        zIndex: 2,
                                        data: data.ohlc,
                                    },
                                    {
                                        showInLegend: false,
                                        type: "column",
                                        name: "Volume",
                                        id: "volume",
                                        data: data.volume,
                                        yAxis: 1,
                                    },
                                    {
                                        type: "vbp",
                                        linkedTo: "aapl",
                                        params: {
                                            volumeSeriesID: "volume",
                                        },
                                        dataLabels: {
                                            enabled: false,
                                        },
                                        zoneLines: {
                                            enabled: false,
                                        },
                                    },
                                    {
                                        type: "sma",
                                        linkedTo: "aapl",
                                        zIndex: 1,
                                        marker: {
                                            enabled: false,
                                        },
                                    },
                                ],
                            };
                            Highcharts.stockChart("container", options);
                        });
                        </script>
                    </body>
                    </html>
    """)
        }
    }
}

struct WebView2: UIViewRepresentable {
    let htmlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlString, baseURL: nil)
    }
}

struct stockPortfolioView: View {
    @Binding var profile: Profile
    @Binding var portfolioItems: [portfolioItem]
    let ticker: String
    let quote: Quote?
//    @State private var portItem: portfolioItem?
    @Binding var cashBalance: Double
    @State var hasShares: Bool = false
    
//    func fetchSinglePortfolioData() async {
//        Task {
//            do {
//                let portItem = portfolioItems.first(where: {$0.Ticker == ticker}) ?? portfolioItem(_id: "", Ticker: "", Name: "", Qty: 0, AvgPrice: 0.0)
//                self.portItem = portItem
//            } catch {
//                print("Error fetching portfolio Item: \(error)")
//            }
//        }
//    }
    var portItem: portfolioItem{
        for item in portfolioItems{
            if(item.Ticker == ticker){
                DispatchQueue.main.async{
                    hasShares = true
                }
                return item
            }
            DispatchQueue.main.async{
                hasShares = false
            }
        }
        return portfolioItem.empty
    }
    
//    var hasShares: Bool {
//        var exists: Bool = false;
//        for item in portfolioItems{
//            if (item.Ticker == ticker){
//                exists = true
//            }
//        }
//        return exists
//    }
    
    var changeInPrice: Double {
        return ((quote?.c ?? 0.0) - (portItem.AvgPrice)) * Double(portItem.Qty)
    }
    
    var totalCost: Double {
        return (portItem.AvgPrice) * Double(portItem.Qty)
    }
    
    var marketValue: Double {
        return (quote?.c ?? 0.00) * Double(portItem.Qty)
    }
    
    var body: some View {
        
        
        VStack{
            HStack {
                Text("Portfolio").font(.title2)
                Spacer()
            }.padding(10)
            
            
            HStack{
                if hasShares {
                    VStack(alignment: .leading){
                        HStack{
                            Text("Shares Owned: ").bold().font(.callout)
                            Text("\(portItem.Qty)").font(.callout)
                        }.padding(.bottom, 10)
                        HStack{
                            Text("Avg. Cost / share: ").bold().font(.callout)
                            Text("$\(portItem.AvgPrice, specifier: "%.2f")").font(.callout)
                        }.padding(.bottom, 10)
                        HStack{
                            Text("Total Cost: ").bold().font(.callout)
                            Text("$\(totalCost, specifier: "%.2f")").font(.callout)
                        }.padding(.bottom, 10)
                        HStack{
                            Text("Change: ").bold().font(.callout)
                            Text("$\(changeInPrice, specifier: "%.2f")").foregroundColor(changeInPrice > 0 ? .green : (changeInPrice < 0 ? .red : .gray))
                        }.padding(.bottom, 10).font(.callout)
                        HStack{
                            Text("Market Value: ").bold().font(.callout)
                            Text("$\(marketValue, specifier: "%.2f")").foregroundColor(changeInPrice > 0 ? .green : (changeInPrice < 0 ? .red : .gray)).font(.callout)
                        }.padding(.bottom, 10)
                    }.padding(.leading, 10)
//                        .task{
//                            await fetchSinglePortfolioData()
//                        }
                }
                else{
                    VStack(alignment: .leading){
                        Text("You have 0 shares of \(ticker).").font(.callout)
                        Text("Start Trading!").font(.callout)
                        
                    }.padding(.leading, 10)
                    
                }
                
                Spacer()
                
                VStack{
                    //                                        Button("Trade", action: {print("trade button clicked")})
                    //                                            .frame(width: 120, height: 40)
                    //                                            .background(Color.green)
                    //                                            .foregroundColor(.white)
                    //                                            .clipShape(Capsule())
                    
                    TradeSheetView(inPortfolio: $hasShares,portfolio: $portfolioItems, name: profile.name,walletAmount: $cashBalance, ticker: ticker, portfolioItem: portItem )
                }.padding(.trailing, 10)
                
            }
        }
        
    }
}

struct statsAndInsightsView: View {
    let ticker: String
    let quote: Quote?
    let profile: Profile?
    @Binding var portfolioItems: [portfolioItem]
    @Binding var cashBalance: Double
    let watchListItems: [watchListItem]
    @State var peers : [String]?
    @State private var sentiment: Sentiment?
    
    
    func fetchPeersData(ticker: String) async {
        do {
            let urlString = "http://localhost:8080/api/peers/\(ticker)"
            let request = AF.request(urlString)
            let response = request.responseDecodable(of: [String].self) { response in
                switch response.result {
                case .success(let peers):
                    self.peers = peers
                case .failure(let error):
                    print("Error fetching peers data: \(error)")
                }
            }
        } catch {
            print("Error fetching peers data: \(error)")
        }
    }
    
    func fetchSentimentData(ticker: String) async {
        let urlString = "http://localhost:8080/api/sentiment/\(ticker)"
        AF.request(urlString).validate().responseDecodable(of: Sentiment.self) { response in
            switch response.result {
            case .success(let sentiment):
                self.sentiment = sentiment
            case .failure(let error):
                print(error)
            }
        }
    }
    
    
    var body: some View {
        
        VStack{
            
            HStack{
                
                VStack(alignment: .leading){
                    HStack {
                        Text("Stats").font(.title2)
                        Spacer()
                    }.padding(10)
                    
                    HStack{
                        VStack{
                            HStack {
                                Text("High Price: ").bold().padding(.bottom, 10).font(.callout)
                                Text("$\(quote?.h ?? 0.0, specifier: "%.2f")").padding(.bottom, 10).font(.callout)
                                
                            }
                            HStack {
                                Text("Low Price: ").bold().padding(.bottom, 10).font(.callout)
                                Text("$\(quote?.l ?? 0.0, specifier: "%.2f")").padding(.bottom, 10).font(.callout)
                            }
                            
                        }.padding(.leading, 10)
                        VStack{
                            HStack {
                                Spacer()
                                Text("Open Price: ").bold().padding(.bottom, 10).font(.callout)
                                Text("$\(quote?.o ?? 0.0, specifier: "%.2f")").padding(.bottom, 10).font(.callout)
                                Spacer()
                            }
                            HStack {
                                Spacer()
                                Text("Close Price: ").bold().padding(.bottom, 10).font(.callout)
                                Text("$\(quote?.c ?? 0.0, specifier: "%.2f")").padding(.bottom, 10).font(.callout)
                                Spacer()
                            }
                            
                        }.padding(.trailing, 10)
                    }
                    
                }
            }
            
            HStack{
                VStack(alignment: .leading){
                    HStack {
                        Text("About").font(.title2)
                        Spacer()
                    }.padding(10)
                    
                    HStack{
                        HStack{
                            VStack(alignment: .leading){
                                HStack {
                                    Text("IPO Start Date: ").bold().padding(.bottom, 5).font(.callout)
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("Industry: ").bold().padding(.bottom, 5).font(.callout)
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("Webpage: ").bold().padding(.bottom, 5).font(.callout)
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("Company Peers: ").bold().padding(.bottom, 5).font(.callout)
                                    Spacer()
                                }
                            }
                        }
                        
                        HStack{
                            VStack(alignment: .leading){
                                HStack{
                                    
                                    Text(profile?.ipo ?? "").padding(.bottom, 5).font(.callout).lineLimit(1)
                                    Spacer()
                                }
                                
                                HStack{
                                    
                                    Text(profile?.finnhubIndustry ?? "").padding(.bottom, 5).font(.callout).lineLimit(1)
                                    Spacer()
                                }
                                
                                HStack{
                                    
                                    if let webURL = profile?.weburl, let url = URL(string: webURL){
                                        Link(destination: url, label: {
                                            Text(webURL).padding(.bottom, 5).font(.callout).lineLimit(1)
                                        })
                                    }
                                    Spacer()
                                }
                                
                                
                                ScrollView(.horizontal) {
                                    if let peers = peers {
                                        HStack {
                                            ForEach(peers, id: \.self) { peer in
                                                
                                                NavigationLink(destination: SingleStock(ticker: peer, portfolioItems: $portfolioItems, cashBalance: $cashBalance, watchListItems: watchListItems)) {
                                                    Text("\(peer), ")
                                                }
                                            }
                                        }
                                    } else {
                                        Text("No peer data available")
                                    }
                                }
                            }
                            Spacer()
                        }
                    }.padding(.leading, 10)
                    
                }
            }
            
            HStack{
                VStack{
                    HStack{
                        Text("Insights").font(.title2)
                        Spacer()
                    }.padding(10)
                    
                    HStack{
                        Spacer()
                        Text("Insider Sentiments").font(.title2)
                        Spacer()
                    }
                    
                    HStack{
                        VStack(alignment: .leading){
                            Text(profile?.name ?? "").bold().padding(5).lineLimit(1)
                            Divider().background(Color.gray)
                            Text("Total").bold().padding(5)
                            Divider().background(Color.gray)
                            Text("Positive").bold().padding(5)
                            Divider().background(Color.gray)
                            Text("Negative").bold().padding(5)
                            Divider().background(Color.gray)
                        }
                        
                        VStack(alignment: .leading){
                            
                            if let sentiment = sentiment {
                                Text("MSPR").bold().padding(5)
                                Divider().background(Color.gray)
                                Text("\(sentiment.totalMsprSum, specifier: "%.2f")").padding(5)
                                Divider().background(Color.gray)
                                Text("\(sentiment.positiveMsprSum, specifier: "%.2f")").padding(5)
                                Divider().background(Color.gray)
                                Text("\(sentiment.negativeMsprSum, specifier: "%.2f")").padding(5)
                                Divider().background(Color.gray)
                            }
                        }
                        
                        VStack(alignment: .leading){
                            
                            if let sentiment = sentiment {
                                Text("Change").bold().padding(5)
                                Divider().background(Color.gray)
                                Text("\(sentiment.totalChangeSum, specifier: "%.2f")").padding(5)
                                Divider().background(Color.gray)
                                Text("\(sentiment.positiveChangeSum, specifier: "%.2f")").padding(5)
                                Divider().background(Color.gray)
                                Text("\(sentiment.negativeChangeSum, specifier: "%.2f")").padding(5)
                                Divider().background(Color.gray)
                            }
                            
                        }
                    }
                }
            }
            
            
            
        }.task {
            await fetchPeersData(ticker: ticker)
            await fetchSentimentData(ticker: ticker)
        }
        
    }
    
}

struct recoChartView: View {
    let ticker: String
    var body: some View {
        WebView(htmlString:"""
                <html>
                  <head>
                    <meta
                      name="viewport"
                      content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"
                    />
                    <style>
                      #container {
                        max-width: 400px;
                        max-height: 400px;
                        width: 100%;
                        height: auto;
                      }
                    </style>
                  </head>
                  <body>
                    <div id="container"></div>
                    <script>
                    const fetchRecs = async (ticker) => {
                        const response = await fetch(`http://127.0.0.1:8080/api/recommendations/${ticker}`);
                        const resJson = await response.json();
                        let strongSell = [];
                        let sell = [];
                        let hold = [];
                        let buy = [];
                        let strongBuy = [];
                        let dates = [];
                        resJson.map((item) => {
                        strongBuy.push(item.strongBuy);
                        buy.push(item.buy);
                        hold.push(item.hold);
                        sell.push(item.sell);
                        strongSell.push(item.strongSell);
                        dates.push(item.period);
                        });
                        let series = {
                        strongBuy,
                        buy,
                        hold,
                        sell,
                        strongSell,
                        dates,
                        };
                        return series;
                    };
                
                      fetchRecs("\(ticker)")
                        .then((data) => {
                          // Work with the parsed JSON data
                          let recs = data;
                          const barOptions = {
                            chart: {
                              height: 400,
                              type: "column",
                              backgroundColor: "#ffffff",
                            },
                            title: {
                              text: "Recommendation Trends",
                              align: "center",
                            },
                            xAxis: {
                              categories: recs.dates,
                            },
                            yAxis: {
                              min: 0,
                              title: {
                                text: "#Analysis",
                              },
                              stackLabels: {
                                enabled: false,
                              },
                            },
                            plotOptions: {
                              column: {
                                stacking: "normal",
                                dataLabels: {
                                  enabled: true,
                                },
                              },
                            },
                            series: [
                              {
                                name: "Strong Buy",
                                data: recs.strongBuy,
                                color: "#19703a",
                              },
                              {
                                name: "Buy",
                                data: recs.buy,
                                color: "#1BAD54",
                              },
                              {
                                name: "Hold",
                                data: recs.hold,
                                color: "#C19725",
                              },
                              {
                                name: "Sell",
                                data: recs.sell,
                                color: "#F06366",
                              },
                              {
                                name: "Strong Sell",
                                data: recs.strongSell,
                                color: "#8A3536",
                              },
                            ],
                          };
                
                          Highcharts.chart("container", barOptions);
                        })
                        .catch((error) => {
                          // Handle any errors that might occur during fetching, processing, or chart rendering
                          console.error("Error:", error);
                        });
                    </script>
                    <script src="https://code.highcharts.com/highcharts.js"></script>
                    <script src="https://code.highcharts.com/modules/exporting.js"></script>
                    <script src="https://code.highcharts.com/modules/export-data.js"></script>
                    <script src="https://code.highcharts.com/modules/accessibility.js"></script>
                  </body>
                </html>
                
                """)
    }
}


struct surpriseChartView: View {
    let ticker: String
    var body: some View {
        WebView(htmlString: """
        <html>
          <head>
            <meta
              name="viewport"
              content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"
            />
            <style>
              #container {
                max-width: 400px;
                max-height: 400px;
                width: 100%;
                height: auto;
              }
            </style>
          </head>
          <body>
            <div id="container"></div>
            <script>
              const fetchEarnings = async (ticker) => {
                const response = await fetch(`http://127.0.0.1:8080/api/earnings/${ticker}`);
                const resJson = await response.json();
                const actualSurpriseArray = [];
                const estimateSurpriseArray = [];
                const timeArr = [];
        
                resJson.forEach((item) => {
                  timeArr.push(`${item.period} <br/> Surprise: ${item.surprise}`);
                  actualSurpriseArray.push([item.period, item.actual]);
                  estimateSurpriseArray.push([item.period, item.estimate]);
                });
                return {
                  timeArr,
                  actualSurpriseArray,
                  estimateSurpriseArray,
                };
              };
        
              fetchEarnings("\(ticker)")
                .then((data) => {
                  // Work with the parsed JSON data
                  let earnings = data;
                  let splineOptions = {
                    chart: {
                      height:400,
                      type: "spline",
                      backgroundColor: "#ffffff",
                    },
                    title: {
                      text: "Historical EPS Surprises",
                      align: "center",
                    },
                    xAxis: {
                      categories: earnings.timeArr,
                    },
                    yAxis: {
                      title: {
                        text: "Quarterly EPS",
                      },
                    },
                    legend: {
                      enabled: true,
                    },
        
                    plotOptions: {
                      spline: {
                        marker: {
                          enable: false,
                        },
                      },
                    },
                    series: [
                      {
                        name: "Actual",
                        data: earnings.actualSurpriseArray,
                      },
                      {
                        name: "Estimate",
                        data: earnings.estimateSurpriseArray,
                      },
                    ],
                  };
                  Highcharts.chart("container", splineOptions);
                })
                .catch((error) => {
                  // Handle any errors that might occur during fetching, processing, or chart rendering
                  console.error("Error:", error);
                });
            </script>
            <script src="https://code.highcharts.com/highcharts.js"></script>
            <script src="https://code.highcharts.com/modules/exporting.js"></script>
            <script src="https://code.highcharts.com/modules/export-data.js"></script>
            <script src="https://code.highcharts.com/modules/accessibility.js"></script>
          </body>
        </html>
        
        """)
    }
}




//#Preview {
//    NavigationView{
//        SingleStock(ticker: "GOOGL", portfolioItems: [portfolioItem(_id: "1", Ticker: "GOOGL", Name: "GOOGLE", Qty: 3, AvgPrice: 133.00)], cashBalance: 25000.00, watchListItems: [watchListItem(Ticker: "GOOGL", Name: "GOOGLE")])
//    }
//}

