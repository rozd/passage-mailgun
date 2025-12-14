import Vapor
import Passage
import Mailgun

public struct MailgunEmailDelivery: Sendable {

    let app: Application
    let configuration: Configuration

    public init(app: Application, configuration: Configuration) {
        self.app = app
        self.configuration = configuration

        app.mailgun.configuration = configuration.mailgun
    }
}

// MARK: - Configuration

extension MailgunEmailDelivery {

    public struct Configuration: Sendable {

        public struct Sender: Sendable {
            let email: String
            let name: String?

            public init(email: String, name: String? = nil) {
                self.email = email
                self.name = name
            }
        }

        public struct Message: Sendable {
            let subject: String
            let template: String

            public init(subject: String, template: String) {
                self.subject = subject
                self.template = template
            }
        }

        public struct Messages: Sendable {
            let welcome: Message
            let verification: Message
            let passwordReset: Message
            let verificationConfirmation: Message
            let magicLink: Message

            public init(
                verification: Message = .init(
                    subject: "Verify your email",
                    template: "email-verification"
                ),
                passwordReset: Message = .init(
                    subject: "Reset your password",
                    template: "password-reset"
                ),
                welcome: Message = .init(
                    subject: "Welcome!",
                    template: "welcome"
                ),
                verificationConfirmation: Message = .init(
                    subject: "Email verified",
                    template: "verification-confirmation"
                ),
                magicLink: Message = .init(
                    subject: "Your magic link",
                    template: "magic-link"
                ),
            ) {
                self.verification = verification
                self.passwordReset = passwordReset
                self.welcome = welcome
                self.verificationConfirmation = verificationConfirmation
                self.magicLink = magicLink
            }
        }

        let mailgun: MailgunConfiguration
        let sender: Sender
        let messages: Messages

        public init(
            mailgun: MailgunConfiguration,
            sender: Sender,
            messages: Messages = .init()
        ) {
            self.mailgun = mailgun
            self.sender = sender
            self.messages = messages
        }
    }

}

extension MailgunEmailDelivery {

    fileprivate func send(
        message: Configuration.Message,
        to email: String,
        user: (any User)?,
        data: [String: String]? = nil,
    ) async throws -> ClientResponse {
        let content = MailgunTemplateMessage(
            from: fromAddress,
            to: email,
            subject: message.subject,
            template: message.template,
            templateData: data
        )
        return try await app.mailgun.client().send(content)
    }

}

// MARK: - Passage.EmailDelivery Conformance

extension MailgunEmailDelivery: Passage.EmailDelivery {

    public func sendEmailVerification(
        to email: String,
        user: any User,
        verificationURL: URL,
        verificationCode: String,
    ) async throws {
        _ = try await send(
            message: configuration.messages.verification,
            to: email,
            user: user,
            data: [
                "verify_url": verificationURL.absoluteString,
                "verify_code": verificationCode,
                "email": email,
                "username": user.username ?? ""
            ]
        )
    }

    public func sendPasswordResetEmail(
        to email: String,
        user: any User,
        passwordResetURL: URL,
        passwordResetCode: String,
    ) async throws {
        _ = try await send(
            message: configuration.messages.passwordReset,
            to: email,
            user: user,
            data: [
                "reset_url": passwordResetURL.absoluteString,
                "reset_code": passwordResetCode,
                "email": email,
                "username": user.username ?? ""
            ]
        )
    }

    public func sendWelcomeEmail(
        to email: String,
        user: any User,
    ) async throws {
        _ = try await send(
            message: configuration.messages.welcome,
            to: email,
            user: user,
            data: [
                "email": email,
                "username": user.username ?? ""
            ]
        )
    }

    public func sendEmailVerificationConfirmation(
        to email: String,
        user: any User,
    ) async throws {
        _ = try await send(
            message: configuration.messages.verificationConfirmation,
            to: email,
            user: user,
            data: [
                "email": email,
                "username": user.username ?? ""
            ]
        )
    }

    public func sendMagicLinkEmail(
        to email: String,
        user: (any User)?,
        magicLinkURL: URL,
    ) async throws {
        _ = try await send(
            message: configuration.messages.magicLink,
            to: email,
            user: user,
            data: [
                "magic_link_url": magicLinkURL.absoluteString,
                "email": email,
                "username": user?.username ?? ""
            ]
        )
    }

    // MARK: - Private Helpers

    private var fromAddress: String {
        if let name = configuration.sender.name {
            return "\(name) <\(configuration.sender.email)>"
        }
        return configuration.sender.email
    }
}
