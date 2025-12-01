//
//  MailgunEmailDelivery.swift
//  passten
//
//  Created by Max Rozdobudko on 11/28/25.
//

import Vapor
@preconcurrency import Mailgun

struct MailgunEmailDelivery: Sendable {

    let app: Application
    let configuration: Configuration

    init(app: Application, configuration: Configuration) {
        self.app = app
        self.configuration = configuration

        app.mailgun.configuration = configuration.mailgun
    }
}

// MARK: - Configuration

extension MailgunEmailDelivery {

    struct Configuration: Sendable {
        struct Sender: Sendable {
            let email: String
            let name: String?
        }

        struct Message: Sendable {
            let subject: String
            let template: String

            init(subject: String, template: String) {
                self.subject = subject
                self.template = template
            }
        }

        struct Messages: Sendable {
            let welcome: Message
            let verification: Message
            let passwordReset: Message
            let verificationConfirmation: Message

            init(
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
                )
            ) {
                self.verification = verification
                self.passwordReset = passwordReset
                self.welcome = welcome
                self.verificationConfirmation = verificationConfirmation
            }
        }

        let mailgun: MailgunConfiguration
        let sender: Sender
        let messages: Messages
    }

}

extension MailgunEmailDelivery {

    fileprivate func send(
        message: Configuration.Message,
        to email: String,
        user: any User,
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

// MARK: - Identity.EmailDelivery Conformance

extension MailgunEmailDelivery: Identity.EmailDelivery {

    func sendEmailVerification(
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

    func sendPasswordResetEmail(
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

    func sendWelcomeEmail(
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

    func sendEmailVerificationConfirmation(
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

    // MARK: - Private Helpers

    private var fromAddress: String {
        if let name = configuration.sender.name {
            return "\(name) <\(configuration.sender.email)>"
        }
        return configuration.sender.email
    }
}
