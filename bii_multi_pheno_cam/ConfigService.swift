//
//  ConfigService.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 1/28/22.
//

import Foundation
import Combine


class ConfigService: ObservableObject {

    @Published private(set) var config: AppConfig
    private let localConfigLoader: LocalConfigLoading
    private let remoteConfigLoader: RemoteConfigLoading
    private var cancellable: AnyCancellable?
    private var syncQueue = DispatchQueue(label: "config_queue_\(UUID().uuidString)")

    init(localConfigLoader: LocalConfigLoading, remoteConfigLoader: RemoteConfigLoading) {
      self.localConfigLoader = localConfigLoader
      self.remoteConfigLoader = remoteConfigLoader

      config = localConfigLoader.fetch()
    }


    func updateConfig() {
        syncQueue.sync {
          guard self.cancellable == nil else {
            return
          }

          self.cancellable = self.remoteConfigLoader.fetch()
            .sink(receiveCompletion: { completion in
              // clear cancellable so we could start a new load
              self.cancellable = nil
            }, receiveValue: { [weak self] newConfig in
              self?.config = newConfig
              self?.localConfigLoader.persist(newConfig)
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

class RemoteConfigLoader: RemoteConfigLoading {
  func fetch() -> AnyPublisher<AppConfig, Error> {
    let configUrl = URL(string: "https://s3.eu-central-1.amazonaws.com/com.donnywals.blog/config.json")!

    return URLSession.shared.dataTaskPublisher(for: configUrl)
      .map(\.data)
      .decode(type: AppConfig.self, decoder: JSONDecoder())
      .eraseToAnyPublisher()
  }
}

protocol LocalConfigLoading {
  func fetch() -> AppConfig
  func persist(_ config: AppConfig)
}

protocol RemoteConfigLoading {
  func fetch() -> AnyPublisher<AppConfig, Error>
}

struct AppConfig: Codable {
  let version: String
}
