//
//  Simple.swift
//  jtinsights
//
//  Created by Alexey Globchastyy on 23/01/2017.
//
//

import Kitura
import KituraStencil
import LoggerAPI
import SwiftyJSON
import Stencil
import KituraTemplateEngine
import PathKit
import ResponseTime
import Foundation
import KituraCompression
import HeliumLogger
import Credentials
import CredentialsGoogle
import KituraSession

public extension URL {
    public func updatedQueryItem(name: String, value: String) -> URL? {
        let queryItems = [URLQueryItem(name: name, value: value)]
        
        let items = self.query?.components(separatedBy: "&")
            .map { $0.components(separatedBy: "=") }
            .map { URLQueryItem(name: $0[0], value: $0[1]) }
            .filter { $0.name != name }
        
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.queryItems = (items ?? []) + queryItems
        return components?.url
    }
    
    public var fullPath: String {
        if let query = self.query {
            return self.path + "?" + query
        } else {
            return self.path
        }
        
    }
}

public protocol Request {
    var query: [String: String] { get }
    var params: [String: String] { get }
    var url: URL { get }
    var hasQuery: Bool { get }
    var json: JSON? { get }
}

extension RouterRequest: Request {
    public var query: [String: String] {
        return queryParameters
    }
    
    public var params: [String: String] {
        return parameters
    }
    
    public var url: URL {
        return urlURL
    }
    
    public var hasQuery: Bool {
        return urlURL.query != nil
    }
    
    public var json: JSON? {
        return readJSON()
    }
}

public protocol Response {
    func render(view: String)
    func render(view: String, context: [String: Any?])
    func error(message: String)
    func error()
    func send(_ dict: [String: Any?])
    func send(_ array: [[String: Any?]]?)
    func send(_ json: JSON?)
    func send(_ string: String?)
    func send(_ array: [JSONConvertable]?)
    func send(_ object: JSONConvertable?)
    func redirect(path: String)
}

extension Response {}
extension RouterResponse: Response {
    public func send(_ string: String?) {
        guard let string = string else {
            return
        }

        send(string)
    }
    
    public func redirect(path: String) {
        _ = try? self.redirect(path)
    }

    public func render(view: String) {
        _ = try? render(view, context: [:])
    }


    public func render(view: String, context: [String: Any?]) {
        _ = try? render(view, context: context)
    }

    public func error() {
        _ = try? send(status: .badRequest).end()
    }

    public func error(message: String) {
        _ = try? send(message).end()
    }

    public func send(_ dict: [String: Any?]) {
        let json = JSON(dict.removedNils)
        send(json)
    }
    
    public func send(_ array: [JSONConvertable]?) {
        send(array?.map { $0.jsonObject })
    }
    
    public func send(_ object: JSONConvertable?) {
        if let object = object?.jsonObject {
            send(object)
        }
    }

    public func send(_ array: [[String: Any?]]?) {
        guard let array = array else {
            return send([:])
        }
        let json = JSON(array.map { $0.removedNils })
        send(json)
    }

    public func send(_ json: JSON?) {
        do {
            let jsonData = try (json ?? JSON.null).rawData(options:.prettyPrinted)
            headers.setType("json", charset: "utf-8")
            _ = try? send(data: jsonData).end()
        } catch {
            self.error(message: error.localizedDescription)
        }
    }

}


open class RouteHandler {
    fileprivate var handlers: [(method: RouterMethod, path: String, handler: RequestHandler)] = []

    public init() {}

    public func get(_ path: String, handler: @escaping RequestHandler) {
        handlers.append((method: .get, path: path, handler: handler))
    }

    public func post(_ path: String, handler: @escaping RequestHandler) {
        handlers.append((method: .post, path: path, handler: handler))
    }
}


public typealias RequestHandler = (Request, Response) -> Void

class SimpleTemplateEngine: TemplateEngine {
    public var fileExtension: String { return "html" }
    private let namespace: Namespace
    
    public init() {
        let namespace = Namespace()
        namespace.registerFilter("url") { (value: Any?) in
            guard let stringValue = value as? String else { return value }
            
            return stringValue.asPath
        }
        
        self.namespace = namespace
    }
    
    public func render(filePath: String, context: [String: Any]) throws -> String {
        let templatePath = Path(filePath)
        let templateDirectory = templatePath.parent()
        let template = try Template(path: templatePath)
        let loader = FileSystemLoader(paths: [templateDirectory])
        var context = context
        context["loader"] = loader
        return try template.render(Context(dictionary: context, namespace: namespace))
    }
}

final class LoggerMiddleware: RouterMiddleware {
    func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        Log.info(request.url.absoluteString)
        next()
    }
}

final class AuthMiddleware: RouterMiddleware {
    weak var router: Router?
    
    private var credentials: Credentials?
    private var session: Session?
    private var googleCredentials: CredentialsGoogle?
    
    var oauth: GoogleAuth? {
        didSet {
            guard let oauth = oauth else { return }
            guard let router = router else { return }
            
            let googleCredentials = CredentialsGoogle(clientId: oauth.id, clientSecret: oauth.secret, callbackUrl: "", options: ["scope":"email"])
            
            let credentials = Credentials()
            credentials.register(plugin: googleCredentials)
            credentials.options["failureRedirect"] = "/auth/login"
            credentials.options["successRedirect"] = "/"
            
            
            self.credentials = credentials
            self.session = Session(secret: oauth.id + oauth.secret)
            self.googleCredentials = googleCredentials
            
            router.get("/auth/login") { request, response, next in
                guard
                    let host = request.url.host,
                    let scheme = request.url.scheme,
                    let port = request.url.port
                else { return response.error() }
                
                let portString: String
                
                if port == 80 {
                    portString = ""
                } else {
                    portString = ":\(port)"
                }
                
                googleCredentials.callbackUrl = scheme + "://" + host + portString + "/auth/login/google/callback"
                
                try? response.send("<!DOCTYPE html><html><body><a href=/auth/login/google>Log In with Google</a></body></html>\n\n").end()
                next()
            }
            router.get("/auth/logout") { request, response, next in
                credentials.logOut(request: request)
                try response.redirect("/auth/login")
                next()
            }
            
            router.get("/auth/login/google",
                       handler: credentials.authenticate(credentialsType: googleCredentials.name))
            router.get("/auth/login/google/callback",
                       handler: credentials.authenticate(credentialsType: googleCredentials.name, failureRedirect: "/login"))
        }
    }
    
    init(router: Router) {
        self.router = router
        credentials = nil
        session = nil
        googleCredentials = nil
    }
    
    func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        guard
            let credentials = credentials,
            let session = session,
            let oauth = oauth,
            let path = request.parsedURL.path
        else {
            if let session = self.session {
                session.handle(request: request, response: response, next: next)
            } else {
                next()
            }
            return
        }
        
        
        if path.hasPrefix("/auth") || path.hasPrefix("/static") {
            session.handle(request: request, response: response, next: next)
            return
        }
        
        session.handle(request: request, response: response) {
            credentials.handle(request: request, response: response) {
                guard let email = request.userProfile?.emails?.first else {
                    _ = try? response.redirect("/auth/logout")
                    next()
                    return
                }
                
                if oauth.accessList.contains(email.value) {
                    next()
                    return
                }
                
                _ = try? response.redirect("/auth/logout")
                next()
            }
        }
    }
}

public struct GoogleAuth {
    fileprivate let id: String
    fileprivate let secret: String
    fileprivate let accessList: [String]
    
    public init(id: String, secret: String, access: [String]) {
        self.id = id
        self.secret = secret
        self.accessList = access
    }
    
    public init(id: String, secret: String, accessFile: String) {
        self.id = id
        self.secret = secret
        
        if let access = GoogleAuth.load(file: accessFile) {
            self.accessList = access
        } else {
            self.accessList = []
        }
    }
    
    
    private static func load(file: String) -> [String]? {
        guard let parentDirectory = #file.components(separatedBy: "/Packages/").first else {
            return nil
        }
        
        let path = Path(parentDirectory + file)
        
        guard let result = try? path.read(.utf8) else {
            return nil
        }
        
        let emails = result
            .trimmingCharacters(in: .newlines)
            .components(separatedBy: .newlines)

        return emails
    }
    

}

public final class Server {
    private let router = Router()
    private let authMiddleware: AuthMiddleware
    
    public var oauth: GoogleAuth? {
        get {
            return authMiddleware.oauth
        }
        set {
            authMiddleware.oauth = newValue
        }
    }
    
    public init() {
        self.authMiddleware = AuthMiddleware(router: router)
        
        
        router.all(middleware: ResponseTime())
        router.all(middleware: self.authMiddleware)
        router.all(middleware: LoggerMiddleware())
        router.all(middleware: Compression())
        router.all("/static", middleware: StaticFileServer())
        router.setDefault(templateEngine: SimpleTemplateEngine())
    }

    
    public func get(_ path: String, handler: @escaping RequestHandler) {
        router.get(path) { (req, res, next) in
            handler(req, res)
            next()
        }
        
    }

    public func post(_ path: String, handler: @escaping RequestHandler) {
        router.post(path) { (req, res, next) in
            handler(req, res)
            next()
        }
    }

    public func listen(httpPort: Int? = nil, fastCGIPort: Int? = nil) {
        if let httpPort = httpPort {
            Kitura.addHTTPServer(onPort: httpPort, with: router)
        }

        if let fastCGIPort = fastCGIPort {
            Kitura.addFastCGIServer(onPort: fastCGIPort, with: router)
        }
        
        Kitura.run()
    }

    public func register(_ path: String, handler: RouteHandler) {
        for value in handler.handlers {
            let fullpath = path + value.path

            switch value.method {
            case .get:
                get(fullpath, handler: value.handler)
            case .post:
                post(fullpath, handler: value.handler)
            default:
                break
            }

        }
    }
    
    public func register(handler: RouteHandler) {
        register("", handler: handler)
    }

}
