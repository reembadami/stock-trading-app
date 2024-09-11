import SwiftUI
import Alamofire

func buyChecks(quantity: String, closePrice: Double, walletAmount: Double) -> String{
    for chr in quantity {
          if !(!(chr >= "a" && chr <= "z") && !(chr >= "A" && chr <= "Z") ) {
              return "Please enter a valid amount"
          }
       }
    if(walletAmount < (Double(quantity) ?? 0.00) * closePrice ){
        return "Not enough money to buy."
    }
    if(Int(quantity) ?? 0 <= 0 ){
        return "Cannot buy non-positive shares"
    }
    
    return "valid"
}

func sellChecks(quantity: String, closePrice: Double, walletAmount: Double, portfolioItem: portfolioItem) -> String{
    for chr in quantity {
          if !(!(chr >= "a" && chr <= "z") && !(chr >= "A" && chr <= "Z") ) {
             return "Please enter a valid amount"
          }
       }
    if(Int(quantity) ?? 0 > portfolioItem.Qty){
        return "Not enough shares to sell"
    }
    if(Int(quantity) ?? 0 <= 0 ){
        return "Cannot sell non-positive shares"
    }
    
    
    return "valid"
}

func buy(ticker: String, name:String, qty: Int, avgPrice: Double){
    let parameters: [String: Any] = [
        "Ticker":ticker,
        "Name":name,
        "Qty":qty,
        "AvgPrice":avgPrice
    ]
    print(parameters)
    let urlString = "http://localhost:8080/api/portfolio/buy";
    _ = AF.request(urlString, method:.post, parameters:parameters, encoding:
                    JSONEncoding.default).response { response in
        switch response.result {
        case .success(_):
            print("Bought item successfully");
        case .failure(let error):
            print("Failed to Buy item: \(error)");
        }
    }
}

func sell(ticker: String, qty: Int, currPrice: Double){
    let parameters: [String: Any] = [
        "Ticker":ticker,
        "Qty":qty,
        "currPrice":currPrice
    ]
    let urlString = "http://localhost:8080/api/portfolio/sell";
    _ = AF.request(urlString, method:.post, parameters:parameters, encoding:
                    JSONEncoding.default).response { response in
        switch response.result {
        case .success(_):
            print("Sold item successfully");
        case .failure(let error):
            print("Failed to sell item: \(error)");
        }
    }
}



struct SheetView: View {
    @Binding var inPortfolio: Bool
    @Environment(\.dismiss) var dismiss
    @Binding var portfolio: [portfolioItem]
    @State private var quantity: String?
    @State private var quote: Quote?
    @State var action: String = ""
    @State private var showSuccessScreen = false
    @State private var showToast = false
    @State private var message = ""
    let name: String
    let ticker: String
    @Binding var walletAmount: Double
    let portfolioItem: portfolioItem
    
    func addToPortfolio() {
        if let index = portfolio.firstIndex(where: { $0.Ticker == ticker }) {
            let oldId: String = portfolio[index]._id
            let oldQty: Int = portfolio[index].Qty
            let oldAvg: Double = portfolio[index].AvgPrice
            let newQty = oldQty + (Int(quantity ?? "0") ?? 0)
            let oldNum: Double = oldAvg * Double(oldQty)
            let newNum: Double = (quote?.c ?? 0.00) * (Double(quantity ?? "") ?? 0.00)
            let newAvg = (oldNum + newNum) / Double(newQty)
            DispatchQueue.main.async{
                inPortfolio=true
            portfolio.remove(at: index)
                let portItem = webtech.portfolioItem(_id: oldId, Ticker: ticker, Name: name, Qty: newQty,  AvgPrice: newAvg)
            portfolio.insert(portItem, at: index)
            }
        }else{
            DispatchQueue.main.async{
                inPortfolio=true
                let portItem = webtech.portfolioItem(_id: "1",  Ticker: ticker, Name: name, Qty: Int(quantity ?? "0") ?? 0, AvgPrice: quote?.c ?? 0.00)
                portfolio.append(portItem)
            }
        }
    }
    func removeFromPortfolio(){
        if let index = portfolio.firstIndex(where: { $0.Ticker == ticker }) {
            if(Int(quantity ?? "") == portfolio[index].Qty){
                portfolio.remove(at: index)
                inPortfolio = false
            }else{
                portfolio[index].Qty -= Int(quantity ?? "") ?? 0            }
            
        }
    }
    
    
    var amount: Double {
        return (quote?.c ?? 0.00) * (Double(quantity ?? "0.00") ?? 0.00)
    }
    
    
    var body: some View {
        let bindingQty = Binding<String>(
            get: {
                if let quantity = self.quantity {
                    return String(quantity)
                } else {
                    return ""
                }
            },
            set: { newValue in
                
                self.quantity = newValue
            }
        )
        VStack{
            
            
            if(showSuccessScreen){
                
                    successView(ticker: ticker, quantity: Int(quantity ?? "0") ?? 0, action: action)
                
            }else{
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.black)
                                .imageScale(.large)
                        }
                        .padding()
                    }
                    Text("Trade \(name) Shares")
                        .bold()
                    Spacer()
                    
                    HStack(alignment: .firstTextBaseline) {
                        TextField("0", text: bindingQty)
                            .keyboardType(.numberPad)
                            .font(.system(size: 150, weight: .regular, design: .default))
                        
                        Spacer()
                        if(Int(quantity ?? "0") ?? 0 > 1){
                            Text("Shares")
                                .font(.system(size:40, weight: .regular, design: .default))
                        }else{
                            Text("Share")
                                .font(.system(size:40, weight: .regular, design: .default))
                        }
                    }
                    .padding(.init(top:0, leading: 10, bottom: 0, trailing: 10))
                    
                    HStack {
                        Spacer()
                        Text("x \(quote?.c ?? 0.00 ,specifier: "%.2f") / share = $\(amount, specifier: "%.2f")")
                            .padding(.trailing)
                    }
                    Spacer()
                    Text("$\(walletAmount, specifier: "%.2f") available to buy \(ticker)")
                    HStack{
                        Button {
                            let check = buyChecks(quantity: quantity ?? "", closePrice: quote?.c ?? 0.00, walletAmount: walletAmount)
                            if(check == "valid"){
                                buy(ticker: ticker, name: name, qty: Int(quantity ?? "0") ?? 0, avgPrice: quote?.c ?? 0.00)
                                self.action = "bought"
                                self.showSuccessScreen = true
                                // add to binding portfolio
                                print()
                                addToPortfolio()
                                walletAmount -= (Double(quantity ?? "") ?? 0.00)*(quote?.c ?? 0.00)
                            }else{
                                self.message = check
                                self.showToast = true
                            }
                                                    } label: {
                            Text("Buy")
                                .padding(.init(top:10, leading: 0, bottom: 10, trailing: 0)).frame(maxWidth: 140)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .buttonBorderShape(.roundedRectangle(radius: 35)).padding()
                        Spacer()
                        Button {
                            // Action for Sell button
                            let check = sellChecks(quantity: quantity ?? "", closePrice: quote?.c ?? 0.00, walletAmount: walletAmount, portfolioItem: portfolioItem)
                            if(check == "valid"){
                                sell(ticker: ticker, qty: Int(quantity ?? "0") ?? 0 , currPrice: quote?.c ?? 0.00)
                                self.action = "sold"
                                self.showSuccessScreen = true
                                removeFromPortfolio()
                                walletAmount += (Double(quantity ?? "") ?? 0.00)*(quote?.c ?? 0.00)
                            }else{
                                self.message = check
                                self.showToast = true
                            }
                            

                        } label: {
                            Text("Sell")
                                .padding(.init(top:10, leading: 0, bottom: 10, trailing: 0)).frame(maxWidth: 140)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .buttonBorderShape(.roundedRectangle(radius: 35)).padding()
                    }
                }.overlay(
                    Toast(message:message, isShowing: $showToast)).task {
                    do {
                        self.quote = try await fetchQuoteData(ticker: ticker)
                    } catch {
                        print("Error fetching quote:", error)
                    }
                }
            }
        }
    }
}

struct TradeSheetView: View {
    @Binding var inPortfolio: Bool
    @Binding var portfolio: [portfolioItem]
    @State private var showingSheet = false
    let name :String
    @Binding var walletAmount: Double
    let ticker: String
    let portfolioItem: portfolioItem
    
    var body: some View {
        
        Button {
            showingSheet.toggle()
        } label: {
            Text("Trade")
                .padding(.init(top:10, leading: 0, bottom: 10, trailing: 0)).frame(maxWidth: 130)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .buttonBorderShape(.roundedRectangle(radius: 35)).padding(.init(top: 60, leading: 0, bottom: 0, trailing: 12)).sheet(isPresented: $showingSheet) {
            SheetView(inPortfolio: $inPortfolio, portfolio: $portfolio, name: name, ticker: ticker, walletAmount: $walletAmount, portfolioItem: portfolioItem)
        }
    }
}

struct successView: View{
    @Environment(\.dismiss) var dismiss
    let ticker: String
    let quantity: Int
    let action: String
    var body: some View{
        VStack{
            Spacer()
            
            Text("Congratulations!").font(.largeTitle).bold().foregroundColor(.white)
            if(quantity > 1){
                Text("You have successfully \(action) \(quantity) shares of \(ticker)").foregroundColor(.white)
            }else{
                Text("You have successfully \(action) \(quantity) share of \(ticker)").foregroundColor(.white)
            }
            
            Spacer()
            Button {
            dismiss()
            } label: {
                Text("Done")
                    .padding(.init(top:10, leading: 0, bottom: 10, trailing: 0)).frame(maxWidth: .infinity).foregroundColor(.green).bold()
            }
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .buttonBorderShape(.roundedRectangle(radius: 35)).padding()
//            Spacer()
        }.background(.green)
    }
}

struct dummyView: View{

    @State var portfolio: [portfolioItem] = [portfolioItem.empty, portfolioItem.empty]
    @State var walletAmount: Double = 25000.00
    @State var inPortfolio: Bool = false
    var body: some View{
        TradeSheetView(inPortfolio: $inPortfolio, portfolio: $portfolio, name: "Microsoft", walletAmount: $walletAmount, ticker: "MSFT", portfolioItem: portfolioItem.empty)
    }
}
#Preview("SingleStock Full") {

    dummyView()
}


