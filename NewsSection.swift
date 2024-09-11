//
//  NewsSection.swift
//  webtech
//
//  Created by Reem Badami on 30/04/24.
//

import SwiftyJSON
import SwiftUI
import Alamofire
import Kingfisher

struct News: Codable {
    let category, headline, image, related, source, summary, url: String
    var datetime, id: Int
    
    static let empty = News(category: "", headline: "", image: "", related: "", source: "", summary: "", url: "", datetime: 0, id: 0)
}

func fetchNewsData(ticker: String) async throws -> [News] {
    let urlString = "http://localhost:8080/api/news/\(ticker)"
    let request = AF.request(urlString)
    let response = try await request.serializingDecodable([News].self).value
    return response
}

struct NewsSection: View {
    let ticker: String
    @State var newsList: [News] = []
    @State var selectedArticle: News = News.empty
    @State var isShowingSheet = false
    
    func formatNewsData() async {
        do {
            let newsList = try await fetchNewsData(ticker: ticker)
            self.newsList = newsList
        } catch {
            print(error)
        }
    }
    
    func timeAgoSinceDate(_ timeInterval: Int) -> String {
        let currentDate = Date()
        let date = Date(timeIntervalSince1970: TimeInterval(timeInterval))
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date, to: currentDate)
        
        var timeDifferenceString = ""
        if let hours = components.hour, let minutes = components.minute {
            if hours > 0 {
                timeDifferenceString += "\(hours) hr"
            }
            if minutes > 0 {
                if !timeDifferenceString.isEmpty {
                    timeDifferenceString += ", "
                }
                timeDifferenceString += "\(minutes) min"
            }
        }
        return timeDifferenceString
    }
    
    var body: some View {
        VStack {
            ForEach(newsList, id: \.id) { article in
                VStack {
                    if article.id == newsList.first?.id ?? 0 {
                        KFImage(URL(string: article.image))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 360, height: 200)
                            .clipped()
                            .cornerRadius(10)
                            .padding([.bottom, .trailing], 10)
                        
                        HStack {
                            Text(article.source).font(.callout)
                            Text(timeAgoSinceDate(article.datetime)).font(.callout).foregroundStyle(Color(.gray))
                            Spacer()
                        }
                        HStack {
                            Text(article.headline).font(.headline)
                            Spacer()
                        }
                        Divider()
                    } else {
                        HStack {
                            VStack {
                                HStack {
                                    Text(article.source).font(.callout)
                                    Text(timeAgoSinceDate(article.datetime)).font(.callout).foregroundStyle(Color(.gray))
                                    Spacer()
                                }
                                HStack {
                                    Text(article.headline).font(.headline)
                                    Spacer()
                                }
                            }
                            KFImage(URL(string: article.image))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipped()
                                .cornerRadius(8)
                        }
                    }
                }.padding(10)
                .onTapGesture {
                    self.selectedArticle = article
                    print("Selected Article:", self.selectedArticle)
                    self.isShowingSheet.toggle()
                }
            }
        }
        .sheet(isPresented: $isShowingSheet) {
            NewsDetailSheet(article: $selectedArticle)
        }
        .task {
            await formatNewsData()
        }
    }
}

struct NewsDetailSheet: View {
    @Binding var article: News
    
    @Environment(\.dismiss) var dismiss
    static let dateFormatter: DateFormatter = {
    
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "multiply")
                        .foregroundColor(.black)
                        .font(.title)
                }
                .padding()
            }
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(article.source).font(.title).bold()
                        }
                        HStack {
                            Text(Self.dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(article.datetime)))).foregroundColor(.gray).font(.callout)
                        }
                    }
                    Spacer()
                    VStack {}
                }
                .background(
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 1)
                        .background(Color(red: 230/255, green: 230/255, blue: 230/255))
                        .padding(.top, 100)
                )
                Text(article.headline)
                    .font(.title3).bold().padding(.top, 30)
                Text(article.summary)
                    .padding(.top, 4).font(.callout)
                HStack {
                    Text("For more details click").foregroundColor(.gray).font(.callout).padding(.top, 4)
                    if let url = URL(string: article.url) {
                        Link("here", destination: url).font(.callout)
                            .padding(.top, 4)
                    }

                }
                VStack {
                    HStack {
                        Button(action: {
                            if let url = URL(string: "https://twitter.com/share?text=\(article.headline)&url=\(article.url)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Image("Twitter")
                                .resizable()
                                .frame(width: 40, height: 40)
                        }
                        Button(action: {
                            if let url = URL(string: "https://www.facebook.com/sharer/sharer.php?u=\(article.url)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Image("Facebook")
                                .resizable()
                                .frame(width: 40, height: 40)
                        }
                    }
                }
                Spacer()
            }
            .padding()
        }
    }
}

//#Preview {
//    NavigationView{
//        SingleStock(ticker: "GOOGL", portfolioItems: [portfolioItem(_id: "1", Ticker: "GOOGL", Name: "GOOGLE", Qty: 3, AvgPrice: 133.00)], cashBalance: 25000.00, watchListItems: [watchListItem(Ticker: "GOOGL", Name: "GOOGLE")])
//    }
//}

