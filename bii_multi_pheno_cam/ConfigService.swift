//
//  ConfigService.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 1/28/22.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift


class ConfigService: ObservableObject {
    
    let defaults = UserDefaults.standard

    @Published private(set) var config: AppConfig
    private let localConfigLoader: LocalConfigLoading
//    private let remoteConfigLoader: RemoteConfigLoading
    private var cancellable: AnyCancellable?
    private var syncQueue = DispatchQueue(label: "config_queue_\(UUID().uuidString)")

    init(localConfigLoader: LocalConfigLoading) {
      self.localConfigLoader = localConfigLoader
//      self.remoteConfigLoader = remoteConfigLoader

      config = localConfigLoader.fetch()
    }


    func updateConfig() {
        syncQueue.sync {
          guard self.cancellable == nil else {
            return
          }

//          self.cancellable = self.remoteConfigLoader.fetch()
            self.cancellable = ConfigPublisher(fileURL: "config")
            .sink(receiveCompletion: { completion in
              // clear cancellable so we could start a new load
              self.cancellable = nil
            }, receiveValue: { [weak self] newConfig in
              print(newConfig.sites![0].id!)
              print(newConfig.sites![0].blocks[1])
              self?.config = newConfig
              self?.localConfigLoader.persist(newConfig)
              self?.defaults.set(Date(), forKey: "lastConfigUpdate")
              self?.cancellable = nil
            })
            
        }
    }
}

class LocalConfigLoader: LocalConfigLoading {
  private var cachedConfigUrl: URL? {
    guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      return nil
    }

    return documentsUrl.appendingPathComponent("config.json")
  }

  private var cachedConfig: AppConfig? {
    let jsonDecoder = JSONDecoder()

    guard let configUrl = cachedConfigUrl,
          let data = try? Data(contentsOf: configUrl),
          let config = try? jsonDecoder.decode(AppConfig.self, from: data) else {
      return nil
    }

    return config
  }

  private var defaultConfig: AppConfig {
    let jsonDecoder = JSONDecoder()

    guard let url = Bundle.main.url(forResource: "config", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let config = try? jsonDecoder.decode(AppConfig.self, from: data) else {
      fatalError("Bundle must include default config. Check and correct this mistake.")
    }

    return config
  }

  func fetch() -> AppConfig {
    if let cachedConfig = self.cachedConfig {
      return cachedConfig
    } else {
      let config = self.defaultConfig
      persist(config)
      return config
    }
  }

  func persist(_ config: AppConfig) {
    guard let configUrl = cachedConfigUrl else {
      // should never happen, you might want to handle this
      print("Error that hasn't been handled in LocalConfigLoader.persist")
      return
    }

    do {
      let encoder = JSONEncoder()
      let data = try encoder.encode(config)
      try data.write(to: configUrl)
    } catch {
      // you could forward this error somewhere
      print(error)
    }
  }
}

//class RemoteConfigLoader: RemoteConfigLoading {
//
//    func fetch() -> AnyPublisher<AppConfig, Error> {
//        let db = Firestore.firestore()
//        let docRef = db.collection("config").document("config")
//          docRef.getDocument{ (document, error) in
//              if let document = document, document.exists {
//                      let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
//                      print("Document data: \(dataDescription)")
//                  } else {
//                      print("Document does not exist")
//                  }
//          }
//
//        let configURL = "config"
//
//        return ConfigPublisher(fileURL: configURL)
//
//        return URLSession.shared.dataTaskPublisher(for: configUrl)
//          .map(\.data)
//          .decode(type: AppConfig.self, decoder: JSONDecoder())
//          .eraseToAnyPublisher()
//    }
//}

protocol LocalConfigLoading {
  func fetch() -> AppConfig
  func persist(_ config: AppConfig)
}

protocol RemoteConfigLoading {
  func fetch() -> AnyPublisher<AppConfig, Error>
}

struct Site: Codable {
  @DocumentID var id: String? // this annotation throws a small error but everything breaks without it. fix me?
  let blocks: [String]
//  let name: String
}

struct AppConfig: Codable {
  var id: String?
  let version: String
  let max_resolution: String
  let frame_rate_seconds: String
  let frame_rate_tolerance_seconds: String
  var sites: [Site]?
}

class FirebaseSubscription<S: Subscriber>: Subscription where S.Input == AppConfig, S.Failure == Error {
    private let fileURL: String
    private var subscriber: S?
    
    init(fileURL: String, subscriber: S) {
        self.fileURL = fileURL
        self.subscriber = subscriber
    }
    
    func request(_ demand: Subscribers.Demand) {
        
        if demand > 0 {
            //load data from firebase
            let db = Firestore.firestore()
            let docRef = db.collection("config").document(fileURL)
            let sitesRef = docRef.collection("sites")
              docRef.getDocument{ (document, error) in
                  if let err = error {
                      // we received an error from firebase
                      self.subscriber?.receive(
                                          completion: .failure(err)
                                      )
//                          let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
//                          print("Document data: \(dataDescription)")
                      } else {
                          // successful request
                          if let document = document, document.exists {
                              // document exists
                              do {
                                  var data = try document.data(as: AppConfig.self)
                                  var sites: [Site] = []
                                  
                                  sitesRef.getDocuments { (querySnapshot, err) in
                                      if let err = err {
                                          print("Error getting site documents")
                                      } else {
                                          do {
                                              for document in querySnapshot!.documents {
                                                  var site = try document.data(as: Site.self)
                                                  if let site = site {
                                                      sites.append(site)
                                                  }
                                              }
                                              
                                              data!.sites = sites
                                              
                                              self.subscriber?.receive(data!) //probably not entirely safe
                                              
                                          } catch {
                                              print("unable to process site documents \(error)")
                                          }
                                      }
                                  }
                              } catch {
                                  //unable to convert config file
                                  self.subscriber?.receive(completion: .failure(NSError(domain: "", code: 501, userInfo: [ NSLocalizedDescriptionKey: "Unable to convert config file"])))
                              }
                          } else {
                              // there was no file at the provided URL
                              self.subscriber?.receive(
                                completion: .failure(NSError(domain: "", code: 404, userInfo: [ NSLocalizedDescriptionKey: "Firestore configuration not found at: \(self.fileURL)"]))
                              )
                          }
                      }
              }
        }
        
        
    }
    
    func cancel() {
        subscriber = nil
    }
}

struct ConfigPublisher: Publisher {
    // The output type of FilePublisher publisher
    typealias Output = AppConfig

    typealias Failure = Error
    
    // fileURL is the url of the file to read
    let fileURL: String
    
    func receive<S>(subscriber: S) where S : Subscriber,
        Failure == S.Failure, Output == S.Input {

        // Create a FileSubscription for the new subscriber
        // and set the file to be loaded to fileURL
        let subscription = FirebaseSubscription(
            fileURL: fileURL,
            subscriber: subscriber
        )
        
        subscriber.receive(subscription: subscription)
    }
}
