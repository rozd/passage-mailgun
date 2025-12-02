import Testing
import Vapor
import XCTVapor
import Mailgun
import Passage
@testable import PassageMailgun

// MARK: - Mocks

final class MockMailgunProvider: MailgunProvider, @unchecked Sendable {
    var sentMessages: [MailgunMessage] = []
    var sentTemplateMessages: [MailgunTemplateMessage] = []
    var shouldFail: Bool = false

    func send(_ content: MailgunMessage) async throws -> ClientResponse {
        if shouldFail {
            throw Abort(.internalServerError, reason: "Mock error")
        }
        sentMessages.append(content)
        return ClientResponse(status: .ok)
    }

    func send(_ content: MailgunTemplateMessage) async throws -> ClientResponse {
        if shouldFail {
            throw Abort(.internalServerError, reason: "Mock error")
        }
        sentTemplateMessages.append(content)
        return ClientResponse(status: .ok)
    }

    func setup(forwarding: MailgunRouteSetup) async throws -> ClientResponse {
        return ClientResponse(status: .ok)
    }

    func createTemplate(_ template: MailgunTemplate) async throws -> ClientResponse {
        return ClientResponse(status: .ok)
    }
}

struct MockUser: User {
    typealias Id = UUID

    var id: UUID?
    var email: String?
    var phone: String?
    var username: String?
    var passwordHash: String?
    var isAnonymous: Bool = false
    var isEmailVerified: Bool = false
    var isPhoneVerified: Bool = false

    static func make(
        id: UUID = UUID(),
        email: String? = "user@example.com",
        username: String? = "testuser"
    ) -> MockUser {
        MockUser(
            id: id,
            email: email,
            username: username
        )
    }
}

// MARK: - Configuration Tests

@Suite("MailgunEmailDelivery Configuration Tests")
struct ConfigurationTests {

    @Suite("Sender")
    struct SenderTests {

        @Test("initializes with email only")
        func initWithEmailOnly() {
            let sender = MailgunEmailDelivery.Configuration.Sender(email: "test@example.com")

            #expect(sender.email == "test@example.com")
            #expect(sender.name == nil)
        }

        @Test("initializes with email and name")
        func initWithEmailAndName() {
            let sender = MailgunEmailDelivery.Configuration.Sender(
                email: "test@example.com",
                name: "Test User"
            )

            #expect(sender.email == "test@example.com")
            #expect(sender.name == "Test User")
        }
    }

    @Suite("Message")
    struct MessageTests {

        @Test("initializes with subject and template")
        func initWithSubjectAndTemplate() {
            let message = MailgunEmailDelivery.Configuration.Message(
                subject: "Test Subject",
                template: "test-template"
            )

            #expect(message.subject == "Test Subject")
            #expect(message.template == "test-template")
        }
    }

    @Suite("Messages")
    struct MessagesTests {

        @Test("initializes with default values")
        func initWithDefaults() {
            let messages = MailgunEmailDelivery.Configuration.Messages()

            #expect(messages.verification.subject == "Verify your email")
            #expect(messages.verification.template == "email-verification")

            #expect(messages.passwordReset.subject == "Reset your password")
            #expect(messages.passwordReset.template == "password-reset")

            #expect(messages.welcome.subject == "Welcome!")
            #expect(messages.welcome.template == "welcome")

            #expect(messages.verificationConfirmation.subject == "Email verified")
            #expect(messages.verificationConfirmation.template == "verification-confirmation")
        }

        @Test("initializes with custom verification message")
        func initWithCustomVerification() {
            let customVerification = MailgunEmailDelivery.Configuration.Message(
                subject: "Custom Verify",
                template: "custom-verification"
            )

            let messages = MailgunEmailDelivery.Configuration.Messages(
                verification: customVerification
            )

            #expect(messages.verification.subject == "Custom Verify")
            #expect(messages.verification.template == "custom-verification")
            #expect(messages.passwordReset.subject == "Reset your password")
        }

        @Test("initializes with custom password reset message")
        func initWithCustomPasswordReset() {
            let customPasswordReset = MailgunEmailDelivery.Configuration.Message(
                subject: "Custom Reset",
                template: "custom-reset"
            )

            let messages = MailgunEmailDelivery.Configuration.Messages(
                passwordReset: customPasswordReset
            )

            #expect(messages.passwordReset.subject == "Custom Reset")
            #expect(messages.passwordReset.template == "custom-reset")
            #expect(messages.verification.subject == "Verify your email")
        }

        @Test("initializes with custom welcome message")
        func initWithCustomWelcome() {
            let customWelcome = MailgunEmailDelivery.Configuration.Message(
                subject: "Custom Welcome",
                template: "custom-welcome"
            )

            let messages = MailgunEmailDelivery.Configuration.Messages(
                welcome: customWelcome
            )

            #expect(messages.welcome.subject == "Custom Welcome")
            #expect(messages.welcome.template == "custom-welcome")
        }

        @Test("initializes with custom verification confirmation message")
        func initWithCustomVerificationConfirmation() {
            let customConfirmation = MailgunEmailDelivery.Configuration.Message(
                subject: "Custom Confirmation",
                template: "custom-confirmation"
            )

            let messages = MailgunEmailDelivery.Configuration.Messages(
                verificationConfirmation: customConfirmation
            )

            #expect(messages.verificationConfirmation.subject == "Custom Confirmation")
            #expect(messages.verificationConfirmation.template == "custom-confirmation")
        }

        @Test("initializes with all custom messages")
        func initWithAllCustomMessages() {
            let messages = MailgunEmailDelivery.Configuration.Messages(
                verification: .init(subject: "V", template: "v"),
                passwordReset: .init(subject: "P", template: "p"),
                welcome: .init(subject: "W", template: "w"),
                verificationConfirmation: .init(subject: "C", template: "c")
            )

            #expect(messages.verification.subject == "V")
            #expect(messages.verification.template == "v")
            #expect(messages.passwordReset.subject == "P")
            #expect(messages.passwordReset.template == "p")
            #expect(messages.welcome.subject == "W")
            #expect(messages.welcome.template == "w")
            #expect(messages.verificationConfirmation.subject == "C")
            #expect(messages.verificationConfirmation.template == "c")
        }
    }
}

// MARK: - Email Delivery Tests

@Suite("Email Delivery Tests")
struct EmailDeliveryTests {

    @Test("sends email verification with correct data")
    func sendEmailVerification() async throws {
        let app = try await Application.make(.testing)
        defer { Task { try await app.asyncShutdown() } }

        let mockProvider = MockMailgunProvider()
        app.mailgun.use { _, _ in mockProvider }

        let config = MailgunEmailDelivery.Configuration(
            mailgun: .init(
                apiKey: "test-api-key",
                defaultDomain: .init("test.mailgun.org", .us)
            ),
            sender: .init(email: "noreply@test.com", name: "Test App")
        )

        let delivery = MailgunEmailDelivery(app: app, configuration: config)
        let user = MockUser.make(username: "johndoe")
        let verificationURL = URL(string: "https://example.com/verify?token=abc123")!

        try await delivery.sendEmailVerification(
            to: "user@example.com",
            user: user,
            verificationURL: verificationURL,
            verificationCode: "123456"
        )

        #expect(mockProvider.sentTemplateMessages.count == 1)

        let message = mockProvider.sentTemplateMessages[0]
        #expect(message.to == "user@example.com")
        #expect(message.from == "Test App <noreply@test.com>")
        #expect(message.subject == "Verify your email")
        #expect(message.template == "email-verification")
        #expect(message.templateData?["verify_url"] == "https://example.com/verify?token=abc123")
        #expect(message.templateData?["verify_code"] == "123456")
        #expect(message.templateData?["email"] == "user@example.com")
        #expect(message.templateData?["username"] == "johndoe")
    }

    @Test("sends password reset email with correct data")
    func sendPasswordResetEmail() async throws {
        let app = try await Application.make(.testing)
        defer { Task { try await app.asyncShutdown() } }

        let mockProvider = MockMailgunProvider()
        app.mailgun.use { _, _ in mockProvider }

        let config = MailgunEmailDelivery.Configuration(
            mailgun: .init(
                apiKey: "test-api-key",
                defaultDomain: .init("test.mailgun.org", .us)
            ),
            sender: .init(email: "noreply@test.com")
        )

        let delivery = MailgunEmailDelivery(app: app, configuration: config)
        let user = MockUser.make(username: "janedoe")
        let resetURL = URL(string: "https://example.com/reset?token=xyz789")!

        try await delivery.sendPasswordResetEmail(
            to: "jane@example.com",
            user: user,
            passwordResetURL: resetURL,
            passwordResetCode: "RESET123"
        )

        #expect(mockProvider.sentTemplateMessages.count == 1)

        let message = mockProvider.sentTemplateMessages[0]
        #expect(message.to == "jane@example.com")
        #expect(message.from == "noreply@test.com")
        #expect(message.subject == "Reset your password")
        #expect(message.template == "password-reset")
        #expect(message.templateData?["reset_url"] == "https://example.com/reset?token=xyz789")
        #expect(message.templateData?["reset_code"] == "RESET123")
        #expect(message.templateData?["email"] == "jane@example.com")
        #expect(message.templateData?["username"] == "janedoe")
    }

    @Test("sends welcome email with correct data")
    func sendWelcomeEmail() async throws {
        let app = try await Application.make(.testing)
        defer { Task { try await app.asyncShutdown() } }

        let mockProvider = MockMailgunProvider()
        app.mailgun.use { _, _ in mockProvider }

        let config = MailgunEmailDelivery.Configuration(
            mailgun: .init(
                apiKey: "test-api-key",
                defaultDomain: .init("test.mailgun.org", .us)
            ),
            sender: .init(email: "hello@test.com", name: "Welcome Bot")
        )

        let delivery = MailgunEmailDelivery(app: app, configuration: config)
        let user = MockUser.make(username: "newuser")

        try await delivery.sendWelcomeEmail(
            to: "newuser@example.com",
            user: user
        )

        #expect(mockProvider.sentTemplateMessages.count == 1)

        let message = mockProvider.sentTemplateMessages[0]
        #expect(message.to == "newuser@example.com")
        #expect(message.from == "Welcome Bot <hello@test.com>")
        #expect(message.subject == "Welcome!")
        #expect(message.template == "welcome")
        #expect(message.templateData?["email"] == "newuser@example.com")
        #expect(message.templateData?["username"] == "newuser")
    }

    @Test("sends email verification confirmation with correct data")
    func sendEmailVerificationConfirmation() async throws {
        let app = try await Application.make(.testing)
        defer { Task { try await app.asyncShutdown() } }

        let mockProvider = MockMailgunProvider()
        app.mailgun.use { _, _ in mockProvider }

        let config = MailgunEmailDelivery.Configuration(
            mailgun: .init(
                apiKey: "test-api-key",
                defaultDomain: .init("test.mailgun.org", .us)
            ),
            sender: .init(email: "noreply@test.com")
        )

        let delivery = MailgunEmailDelivery(app: app, configuration: config)
        let user = MockUser.make(username: "verifieduser")

        try await delivery.sendEmailVerificationConfirmation(
            to: "verified@example.com",
            user: user
        )

        #expect(mockProvider.sentTemplateMessages.count == 1)

        let message = mockProvider.sentTemplateMessages[0]
        #expect(message.to == "verified@example.com")
        #expect(message.from == "noreply@test.com")
        #expect(message.subject == "Email verified")
        #expect(message.template == "verification-confirmation")
        #expect(message.templateData?["email"] == "verified@example.com")
        #expect(message.templateData?["username"] == "verifieduser")
    }

    @Test("handles user without username")
    func handlesUserWithoutUsername() async throws {
        let app = try await Application.make(.testing)
        defer { Task { try await app.asyncShutdown() } }

        let mockProvider = MockMailgunProvider()
        app.mailgun.use { _, _ in mockProvider }

        let config = MailgunEmailDelivery.Configuration(
            mailgun: .init(
                apiKey: "test-api-key",
                defaultDomain: .init("test.mailgun.org", .us)
            ),
            sender: .init(email: "noreply@test.com")
        )

        let delivery = MailgunEmailDelivery(app: app, configuration: config)
        let user = MockUser.make(username: nil)

        try await delivery.sendWelcomeEmail(
            to: "noname@example.com",
            user: user
        )

        #expect(mockProvider.sentTemplateMessages.count == 1)

        let message = mockProvider.sentTemplateMessages[0]
        #expect(message.templateData?["username"] == "")
    }

    @Test("uses custom message templates")
    func usesCustomMessageTemplates() async throws {
        let app = try await Application.make(.testing)
        defer { Task { try await app.asyncShutdown() } }

        let mockProvider = MockMailgunProvider()
        app.mailgun.use { _, _ in mockProvider }

        let config = MailgunEmailDelivery.Configuration(
            mailgun: .init(
                apiKey: "test-api-key",
                defaultDomain: .init("test.mailgun.org", .us)
            ),
            sender: .init(email: "noreply@test.com"),
            messages: .init(
                verification: .init(
                    subject: "Custom: Please verify",
                    template: "custom-verify-template"
                )
            )
        )

        let delivery = MailgunEmailDelivery(app: app, configuration: config)
        let user = MockUser.make()
        let verificationURL = URL(string: "https://example.com/verify")!

        try await delivery.sendEmailVerification(
            to: "user@example.com",
            user: user,
            verificationURL: verificationURL,
            verificationCode: "CODE"
        )

        #expect(mockProvider.sentTemplateMessages.count == 1)

        let message = mockProvider.sentTemplateMessages[0]
        #expect(message.subject == "Custom: Please verify")
        #expect(message.template == "custom-verify-template")
    }
}

// MARK: - Type Conformance Tests

@Suite("Type Conformance Tests")
struct TypeConformanceTests {

    @Test("Sender is Sendable")
    func senderIsSendable() {
        let sender = MailgunEmailDelivery.Configuration.Sender(email: "test@example.com")
        let _: any Sendable = sender
    }

    @Test("Message is Sendable")
    func messageIsSendable() {
        let message = MailgunEmailDelivery.Configuration.Message(
            subject: "Test",
            template: "test"
        )
        let _: any Sendable = message
    }

    @Test("Messages is Sendable")
    func messagesIsSendable() {
        let messages = MailgunEmailDelivery.Configuration.Messages()
        let _: any Sendable = messages
    }

    @Test("MailgunEmailDelivery is Sendable")
    func mailgunEmailDeliveryIsSendable() {
        func acceptsSendable<T: Sendable>(_ type: T.Type) {}
        acceptsSendable(MailgunEmailDelivery.self)
    }
}
