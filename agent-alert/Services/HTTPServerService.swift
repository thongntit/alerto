import Foundation
import Hummingbird
import NIOFoundationCompat
import Logging
import Combine
import ServiceLifecycle

enum HTTPServerStatus: Equatable {
    case stopped
    case running(port: Int)
    case error(message: String)
    
    var displayText: String {
        switch self {
        case .stopped:
            return "HTTP: Stopped"
        case .running(let port):
            return "HTTP: Running on port \(port)"
        case .error(let message):
            return "HTTP: Error - \(message)"
        }
    }
}

@MainActor
class HTTPServerManager: ObservableObject {
    static let shared = HTTPServerManager()
    
    @Published var status: HTTPServerStatus = .stopped
    @Published var port: Int = 7531
    
    private var app: Application<RouterResponder<BasicRequestContext>>?
    private var serviceGroup: ServiceGroup?
    private var serverTask: Task<Void, Never>?
    private var startTime: Date?
    private let logger = Logger(label: "com.agent-alert.http-server")
    
    private init() {
        if let savedPort = UserDefaults.standard.object(forKey: "httpPort") as? Int {
            self.port = savedPort
        }
    }
    
    var uptime: Int {
        guard let startTime = startTime else { return 0 }
        return Int(Date().timeIntervalSince(startTime))
    }
    
    func start() async {
        guard app == nil else { return }
        
        let router = Router()
        
        router.post("/notify") { request, context in
            return try await self.handleNotify(request: request, context: context)
        }
        
        router.get("/notify") { request, context in
            return try await self.handleNotify(request: request, context: context)
        }
        
        router.get("/health") { request, context in
            return try await self.handleHealth(request: request, context: context)
        }
        
        do {
            let app = Application(
                router: router,
                configuration: .init(
                    address: .hostname("127.0.0.1", port: self.port),
                    serverName: "agent-alert"
                )
            )
            
            self.app = app
            self.startTime = Date()
            self.status = .running(port: self.port)
            
            logger.info("HTTP server started on port \(self.port)")
            
            let serviceGroup = ServiceGroup(
                configuration: .init(
                    services: [app],
                    logger: logger
                )
            )
            
            self.serviceGroup = serviceGroup
            
            serverTask = Task {
                do {
                    try await serviceGroup.run()
                } catch {
                    await MainActor.run {
                        if !Task.isCancelled {
                            let errorMessage = error.localizedDescription
                            if errorMessage.contains("Address already in use") || errorMessage.contains("EADDRINUSE") {
                                self.status = .error(message: "Port \(self.port) is already in use")
                            } else {
                                self.status = .error(message: errorMessage)
                            }
                            logger.error("HTTP server error: \(error)")
                        }
                    }
                }
            }
        } catch {
            let errorMessage = error.localizedDescription
            if errorMessage.contains("Address already in use") || errorMessage.contains("EADDRINUSE") {
                self.status = .error(message: "Port \(self.port) is already in use")
            } else {
                self.status = .error(message: errorMessage)
            }
            logger.error("Failed to start HTTP server: \(error)")
        }
    }
    
    func stop() async {
        serverTask?.cancel()
        serverTask = nil
        
        self.app = nil
        self.serviceGroup = nil
        self.startTime = nil
        self.status = .stopped
        
        logger.info("HTTP server stopped")
    }
    
    func restart() async {
        await stop()
        try? await Task.sleep(nanoseconds: 100_000_000)
        await start()
    }
    
    func updatePort(_ newPort: Int) async {
        guard newPort != port else { return }
        port = newPort
        UserDefaults.standard.set(newPort, forKey: "httpPort")
        
        if case .running = status {
            await restart()
        }
    }
    
    private func handleNotify(request: Request, context: BasicRequestContext) async throws -> Response {
        var source: String?
        var type: String?
        var message: String?
        
        if let query = request.uri.query {
            let params = parseQueryParams(query)
            source = params["source"]
            type = params["type"]
            message = params["message"]
        }
        
        if request.method == .post {
            if let body = try? await request.body.collect(upTo: 1024 * 1024),
               body.readableBytes > 0 {
                let data = body.getData(at: 0, length: body.readableBytes) ?? Data()
                if let json = try? JSONDecoder().decode(NotifyRequest.self, from: data) {
                    source = source ?? json.source
                    type = type ?? json.type
                    message = message ?? json.message
                }
            }
        }
        
        guard let sourceValue = source, !sourceValue.isEmpty else {
            return Response(
                status: .badRequest,
                body: .init(byteBuffer: ByteBuffer(string: #"{"error": "Missing required parameter: source"}"#))
            )
        }
        
        guard let typeValue = type, !typeValue.isEmpty else {
            return Response(
                status: .badRequest,
                body: .init(byteBuffer: ByteBuffer(string: #"{"error": "Missing required parameter: type"}"#))
            )
        }
        
        guard let messageValue = message, !messageValue.isEmpty else {
            return Response(
                status: .badRequest,
                body: .init(byteBuffer: ByteBuffer(string: #"{"error": "Missing required parameter: message"}"#))
            )
        }
        
        guard let notificationSource = NotificationSource(rawValue: sourceValue) else {
            return Response(
                status: .badRequest,
                body: .init(byteBuffer: ByteBuffer(string: #"{"error": "Invalid source: \(sourceValue)"}"#))
            )
        }
        
        guard let notificationType = NotificationType(rawValue: typeValue) else {
            return Response(
                status: .badRequest,
                body: .init(byteBuffer: ByteBuffer(string: #"{"error": "Invalid type: \(typeValue)"}"#))
            )
        }
        
        await MainActor.run {
            NotificationManager.shared.handleNotification(
                source: notificationSource,
                type: notificationType,
                message: messageValue
            )
        }
        
        return Response(
            status: .ok,
            body: .init(byteBuffer: ByteBuffer(string: #"{"success": true}"#))
        )
    }
    
    private func handleHealth(request: Request, context: BasicRequestContext) async throws -> Response {
        let uptime = self.uptime
        let response = HealthResponse(status: "ok", uptime: uptime)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        
        return Response(
            status: .ok,
            body: .init(byteBuffer: ByteBuffer(data: data))
        )
    }
    
    private func parseQueryParams(_ query: String) -> [String: String] {
        var params: [String: String] = [:]
        let pairs = query.split(separator: "&")
        
        for pair in pairs {
            let components = pair.split(separator: "=", maxSplits: 1)
            guard components.count == 2 else { continue }
            
            let key = String(components[0])
            let value = String(components[1]).removingPercentEncoding ?? String(components[1])
            params[key] = value
        }
        
        return params
    }
}

private struct NotifyRequest: Codable {
    let source: String
    let type: String
    let message: String
}

private struct HealthResponse: Codable {
    let status: String
    let uptime: Int
}
