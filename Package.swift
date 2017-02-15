import PackageDescription

let package = Package(
    name: "Simple",
    dependencies: [
      .Package(url: "https://github.com/IBM-Swift/Kitura.git", majorVersion: 1),
      .Package(url: "https://github.com/IBM-Swift/Kitura-ResponseTime.git", majorVersion: 1),
      .Package(url: "https://github.com/IBM-Swift/Kitura-StencilTemplateEngine.git", majorVersion: 1),
      .Package(url: "https://github.com/IBM-Swift/Kitura-Compression.git", majorVersion: 1),
      .Package(url: "https://github.com/IBM-Swift/Kitura-CredentialsHTTP.git", majorVersion: 1),
      .Package(url: "https://github.com/IBM-Swift/Kitura-CredentialsGoogle.git", majorVersion: 1),
      .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", majorVersion: 1),
      .Package(url: "https://github.com/globchastyy/Http.git", majorVersion: 0)
    ]
)
