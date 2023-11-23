//
//  ContentView.swift
//  WsbClassifier
//
//  Created by Francisco Gaieski on 23/11/23.
//

import SwiftUI

struct ContentView: View {
    
    @State private var currentTitle: Title = Title(title: "WSB Classifier", classification: "", id: -1)
    @State private var titles: [Title] = []
    @State private var isLoading: Bool = false
    
    var apiUrl: URL? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path) as? [String: Any],
              let apiUrlString = config["ApiUrl"] as? String,
              let url = URL(string: apiUrlString) else {
            print("Erro ao ler a URL da API do arquivo Config.plist")
            return nil
        }
        return url
    }
    
    struct Titles: Codable {
        var titles: [Title]
    }
    
    struct Title: Codable {
        var title: String
        var classification: String?
        var id: Int
    }
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading...")
                    .padding()
            }
            else {
                
                
                Text(currentTitle.title)
                    .font(.headline)
                    .padding()
                
                HStack {
                    Button("Negative") { classifyTitle(classification: "Negative") }.buttonStyle(.borderedProminent)
                        .tint(.red)
                    Button("Neither") { classifyTitle(classification: "Neither") }.buttonStyle(.borderedProminent)
                        .tint(.brown)
                    Button("Positive") { classifyTitle(classification: "Positive") }.buttonStyle(.borderedProminent)
                        .tint(.green)
                }
                .padding()
            }
        }
        .onAppear {
            // Carrega o primeiro título ao iniciar o aplicativo
            getNextTitles()
        }
    }
    func getNextTitles() {
        guard let baseUrl = apiUrl else {
            return
        }
        isLoading = true
        
        guard let url = URL(string: "\(String(describing: baseUrl))/titles") else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            defer {
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
            if let data = data {
                do {
                    // Decodifica os dados JSON para obter o título
                    let titlesArray = try JSONDecoder().decode(Titles.self, from: data)
                    DispatchQueue.main.async {
                        if let firstTitle = titlesArray.titles.first {
                            self.titles = titlesArray.titles
                            self.currentTitle = firstTitle
                            print(titles)
                        }
                    }
                } catch {
                    print("Erro ao decodificar o título: \(error.localizedDescription)")
                }
            } else if let error = error {
                print("Erro ao obter o próximo título: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    func classifyTitle(classification: String) {
        guard let baseUrl = apiUrl else {
            return
        }
        isLoading = true
        
        guard let url = URL(string: "\(String(describing: baseUrl))/titles") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Cria o corpo da solicitação com o ID e a classificação
        let body: [String: Any] = [
            "id": currentTitle.id,
            "classification": classification
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Erro ao serializar o corpo da solicitação: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { _, _, error in
            defer {
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
            if let error = error {
                print("Erro ao enviar a classificação: \(error.localizedDescription)")
            } else {
                handleNextTitle()
            }
        }.resume()
    }
    
    func handleNextTitle() {
        self.titles.removeFirst()
        if let firstTitle = titles.first {
            self.currentTitle = firstTitle
        } else {
            getNextTitles()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
