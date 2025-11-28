//
//  MailgunEmailDelivery.swift
//  passten
//
//  Created by Max Rozdobudko on 11/28/25.
//

struct MailgunEmailDelivery: Sendable {

    func send

}

extension MailgunEmailDelivery: Identity.Verification.EmailDelivery {

    func sendVerificationEmail(
        to email: String,
        code: String,
        user: any User,
    ) async throws {

    }

    func sendPasswordResetEmail(
        to email: String,
        code: String,
        user: any User,
    ) async throws {
        <#code#>
    }

    func sendWelcomeEmail(
        to email: String,
        user: any User,
    ) async throws {
        <#code#>
    }

    func sendVerificationConfirmation(
        to email: String,
        user: any User,
    ) async throws {
        <#code#>
    }


}
