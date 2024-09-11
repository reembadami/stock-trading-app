//
//  ContentView.swift
//  webtech
//
//  Created by Reem Badami on 11/04/24.
//

import SwiftUI
import SwiftyJSON
import Alamofire

struct portfolioItem: Codable {
    var _id: String
    var Ticker: String
    var Name: String
    var Qty: Int
    var AvgPrice: Double
    static let empty = portfolioItem(_id: "", Ticker: "", Name: "", Qty:0, AvgPrice:0.00);
}

struct Quote:  Codable {
    let c, d, dp, h: Double
    let l, o, pc: Double
    let t: Int
}

struct watchListItem: Codable {
    let Ticker: String
    let Name: String
}

func fetchCashBalance() async throws -> Double {
    let urlString = "http://localhost:8080/api/wallet"
    let request = AF.request(urlString)
    let response = try await request.serializingDecodable(JSON.self).value
    return response["response"]["Amount"].doubleValue
}

func fetchPortfolioItems() async throws -> [portfolioItem] {
    let urlString = "http://localhost:8080/api/portfolio"
    let request = AF.request(urlString)
    let response = try await request.serializingDecodable([portfolioItem].self).value
    return response
}

func fetchQuoteData(ticker: String) async throws -> Quote {
    let urlString = "http://localhost:8080/api/quote/\(ticker)"
    let request = AF.request(urlString)
    let response = try await request.serializingDecodable(Quote.self).value
    return response
}

func fetchWatchlistData() async throws -> [watchListItem] {
    let urlString = "http://localhost:8080/api/watchlist"
    let request = AF.request(urlString)
    let response = try await request.serializingDecodable([watchListItem].self).value
    return response
}

struct SearchResult: Codable {
    var symbol: String
    var description: String
}

func fetchSearchResults(ticker: String) async throws -> [SearchResult] {
    let urlString = "http://localhost:8080/api/search/\(ticker)"
    let request = AF.request(urlString)
    let response = try await request.serializingDecodable([SearchResult].self).value
    return response
    }

//CHANGES

struct ContentView: View {
    @State var loading = true
    @State var searchText = ""
    @State private var searchResults : [SearchResult] = []
    @State private var cashBalance : Double = 0.0
    @State private var portfolioItems : [portfolioItem] = []
    @State private var quotes: [String: Quote] = [:]
    @State private var watchlistItems: [watchListItem] = []
    @Environment(\.isSearching) private var isSearching
    
    let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter
        }()
    
    
    func fetchAll() async {
        do {
            loading = true
            let balance = try await fetchCashBalance()
            cashBalance = balance
            
            let portfolioItemsList = try await fetchPortfolioItems()
            portfolioItems = portfolioItemsList
            
            for item in portfolioItemsList{
                let quote = try await fetchQuoteData(ticker: item.Ticker)
                quotes[item.Ticker] = quote
            }
                
            let watchlistItemsList = try await fetchWatchlistData()
            watchlistItems = watchlistItemsList
                
            for item in watchlistItemsList{
                let quote = try await fetchQuoteData(ticker: item.Ticker)
                quotes[item.Ticker] = quote
            
            }
            loading = false
        } catch {
            print(error)
        }
    }
    
    var body: some View {
        
            VStack{
//            if loading {
//                    ProgressView("Fetching Data...")
//            }
//            else{
                VStack{
                    NavigationStack{
                        VStack{
                            if !loading || searchText != "" {
                                
                                    
                                    listView(searchText: $searchText, searchResults: $searchResults, cashBalance: $cashBalance, portfolioItems: $portfolioItems, quotes: quotes, watchlistItems:$watchlistItems).searchable(text: $searchText, prompt: "Search").onChange(of: searchText){ searchText in
                                        Task{
                                            self.searchResults = 
                                            if (searchText.count>2){
                                                try await fetchSearchResults(ticker: searchText)}
                                            else{[]}
                                        
                                        }
                                if searchText.isEmpty && !isSearching {
                                                                    //Search cancelled here
                                                                    self.searchResults = []
                                                                
                                                                }
                                    }
                                
                            }
                        else if loading {
                            ProgressView("Fetching Data...")
                        }
                    }.navigationTitle("Stocks")
                            .task {
                                await fetchAll()
                            }
                    }
                    
                    Spacer()
                }
                .edgesIgnoringSafeArea(.bottom)
        
            
    }
        
    }
}

struct listView: View{
    @Binding var searchText : String
    @Binding var searchResults : [SearchResult]
    @Binding var cashBalance : Double
    @Binding var portfolioItems : [portfolioItem]
    let quotes: [String: Quote]
    @Binding var watchlistItems: [watchListItem]
    @Environment(\.isSearching) private var isSearching
    
    var netWorth: Double {
        
        var totalNetWorth = 0.0
        for item in portfolioItems{
            totalNetWorth += (quotes[item.Ticker]?.c ?? 0) * Double(item.Qty)
        }
        return totalNetWorth + cashBalance
    }
    
    let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter
        }()
    
    private func delete(at offsets: IndexSet) {
        var indicesToRemove = Array(offsets)
        var index = indicesToRemove[0]
        print(index)
        var ticker = watchlistItems[index].Ticker
        watchlistItems.remove(at: index)
        let url = "http://localhost:8080/api/watchlist/\(ticker)"
        AF.request(url, method: .delete).response { response in
            switch response.result {
            case .success(_):
                print("Watchlist item deleted successfully")
            case .failure(let error):
                print("Failed to delete watchlist item: \(error)")
            }
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        print("Move function")
    }
    
    var body: some View{
        if(!isSearching && searchText == ""){
            List {
                HStack {
                    Text(dateFormatter.string(from: Date())).font(.largeTitle).bold().foregroundStyle(Color(.gray))
                }
                
                Section(
                    header: Text("PORTFOLIO")
                ){
                    
                    HStack{
                        VStack{
                            HStack{
                                Text("Net Worth").font(.title2)
                                Spacer()
                            }
                            
                            HStack{
                                Text("$\(netWorth, specifier: "%.2f")").bold().font(.title2)
                                Spacer()
                            }
                        }
                        
                        
                        VStack{
                            HStack{
                                Text("Cash Balance").font(.title2)
                                
                            }
                            
                            HStack{
                                Text("$\(String(format: "%.2f", cashBalance))").bold().font(.title2)
                            }
                        }
                        
                    }
                    ForEach(portfolioItems, id: \._id) { item in
                        NavigationLink(
                            destination: SingleStock(ticker: item.Ticker, portfolioItems: $portfolioItems, cashBalance: $cashBalance, watchListItems: watchlistItems),
                            label: {
                                portfolioView(item: item, quotes: quotes)})
                        
                    }
                }
                
                Section(
                    header: Text("FAVORITES")
                ){
                    ForEach(watchlistItems, id: \.Ticker) { item in
                        NavigationLink(
                            destination: SingleStock(ticker: item.Ticker, portfolioItems: $portfolioItems, cashBalance: $cashBalance, watchListItems: watchlistItems),
                            label: {favouritesView(item: item, quotes: quotes)})
                    }.onDelete(perform: delete).onMove{watchlistItems.move(fromOffsets: $0, toOffset: $1)}
                    
                    
                    
                }
                
                Link(destination: URL(string: "https://finnhub.io")!){
                    HStack{
                        Spacer()
                        Text("Powered by Finnhub.io").font(.callout).foregroundStyle(Color(.gray))
                        Spacer()
                    }
                }
                
            }.toolbar{EditButton()}
        }else{
            SearchView(searchText: $searchText, searchResults: $searchResults, portfolioItems: $portfolioItems, cashBalance: $cashBalance, watchListItems: watchlistItems)
        }
    }
}

struct favouritesView: View{
    let item: watchListItem
    let quotes: [String: Quote]
    var body: some View{
        HStack{
            VStack{
                HStack{
                    Text(item.Ticker).font(.title3).bold()
                    Spacer()
                }
                
                HStack{
                    Text(item.Name).foregroundStyle(Color(.gray)).font(.callout)
                    Spacer()
                }
            }
            
            
            VStack{
                HStack{
                    Spacer()
                    Text("$\((quotes[item.Ticker]?.c ?? 0.00), specifier: "%.2f")").font(.title2).bold()
                }
                
                HStack{
                    Spacer()
                    
                    if let d = quotes[item.Ticker]?.d {
                                switch d {
                                case let x where x > 0:
                                    Image(systemName: "arrow.up.right").foregroundColor(.green)
                                case let x where x < 0:
                                    Image(systemName: "arrow.down.right").foregroundColor(.red)
                                default:
                                    Image(systemName: "minus").foregroundColor(.gray)
                                }
                            }
                    
                    Text("$\(quotes[item.Ticker]?.d ?? 0.00, specifier: "%.2f") (\(quotes[item.Ticker]?.dp ?? 0.00, specifier: "%.2f%%"))").font(.title3).fixedSize(horizontal: true, vertical: true).foregroundColor((quotes[item.Ticker]?.d ?? 0.00) > 0 ? .green : ((quotes[item.Ticker]?.d ?? 0.00) < 0 ? .red : .gray))
                    
                }
                
            }
            
        }

    }
}

struct portfolioView: View{
    let item: portfolioItem
    let quotes: [String: Quote]
    
    var body: some View {
        var changeInPrice: Double {
            return ((quotes[item.Ticker]? .c ?? 0.00)  - item.AvgPrice) * Double(item.Qty)
        }
        
        var changePercent: Double{
            let change = changeInPrice;
            let originalCost = item.AvgPrice * Double(item.Qty)
            
            return (change/originalCost)*100
        }
        
        var marketValue: Double {
            return (quotes[item.Ticker]?.c ?? 0.00) * Double(item.Qty)
        }
        
        HStack{
            VStack{
                HStack{
                    Text(item.Ticker).font(.title2).bold()
                    Spacer()
                }
                
                HStack{
                    Text("\(item.Qty) shares").foregroundStyle(Color(.gray)).font(.callout)
                    Spacer()
                }
            }
            
            
            VStack{
                HStack{
                    Spacer()
                    Text("$\(marketValue, specifier: "%.2f")").font(.title2).bold()
                    
                }
                
                HStack{
                    Spacer()
                    Text("$\(changeInPrice, specifier: "%.2f") (\(changePercent, specifier: "%.2f")%)").font(.title3).fixedSize(horizontal: true, vertical: true).foregroundColor(changeInPrice > 0 ? .green : (changeInPrice < 0 ? .red : .gray))
                    
                }
                
                
            }
            
        }
    }
}

struct SearchView: View {
    @Binding var searchText: String
    @Binding var searchResults: [SearchResult]
    @Binding var portfolioItems : [portfolioItem]
    @Binding var cashBalance : Double
    var watchListItems: [watchListItem]
    
    var body: some View{
            List {
                if searchText != "" {
                ForEach(searchResults, id: \.symbol) {searchResult in
                    NavigationLink(destination: SingleStock(ticker: searchResult.symbol, portfolioItems: $portfolioItems, cashBalance: $cashBalance, watchListItems: watchListItems)){
                        VStack(alignment: .leading) {
                            Text(searchResult.symbol)
                            Text(searchResult.description)
                        }
                    }
                }
            }
            }
    }
    }

#Preview {
    ContentView()
}
