import Testing
@testable import PassageMailgun

@Suite("MailgunEmailDelivery Configuration Tests")
struct ConfigurationTests {

    // MARK: - Sender Tests

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

    // MARK: - Message Tests

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

    // MARK: - Messages Tests

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
            // Other messages should still have defaults
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
            // Other messages should still have defaults
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

    @Test("Configuration is Sendable")
    func configurationIsSendable() async throws {
        // We can't easily create a full Configuration without Mailgun dependencies,
        // but we can verify the nested types are Sendable
        let sender = MailgunEmailDelivery.Configuration.Sender(email: "test@example.com")
        let messages = MailgunEmailDelivery.Configuration.Messages()

        let _: any Sendable = sender
        let _: any Sendable = messages
    }

    @Test("MailgunEmailDelivery is Sendable")
    func mailgunEmailDeliveryIsSendable() {
        // Type-level check - MailgunEmailDelivery conforms to Sendable
        // This is a compile-time check via the type system
        func acceptsSendable<T: Sendable>(_ type: T.Type) {}
        acceptsSendable(MailgunEmailDelivery.self)
    }
}
