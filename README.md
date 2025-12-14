# passage-mailgun

[![Release](https://img.shields.io/github/v/release/rozd/passage-mailgun)](https://github.com/rozd/passage-mailgun/releases)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![License](https://img.shields.io/github/license/rozd/passage-mailgun)](LICENSE)
[![codecov](https://codecov.io/gh/rozd/passage-mailgun/branch/main/graph/badge.svg)](https://codecov.io/gh/rozd/passage-mailgun)

Mailgun email delivery implementation for [Passage](https://github.com/vapor-community/passage) authentication framework.

This package provides a bridge between Passage and [Mailgun](https://github.com/vapor-community/mailgun), enabling Passage to send authentication emails (verification, password reset, magic links, etc.) via Mailgun's API.

> **Note:** This package cannot be used standalone. It requires both [Passage](https://github.com/vapor-community/passage) and [Mailgun](https://github.com/vapor-community/mailgun) packages to function.

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/rozd/passage-mailgun.git", from: "0.0.1"),
]
```

Then add `PassageMailgun` to your target dependencies:

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "PassageMailgun", package: "passage-mailgun"),
    ]
)
```

## Configuration

Configure `MailgunEmailDelivery` with your Mailgun credentials and sender information:

```swift
import Passage
import PassageMailgun

let emailDelivery = MailgunEmailDelivery(
    app: app,
    configuration: .init(
        mailgun: .init(
            apiKey: "your-mailgun-api-key",
            defaultDomain: .init("mail.yourdomain.com", .us)
        ),
        sender: .init(
            email: "noreply@yourdomain.com",
            name: "Your App"  // optional
        )
    )
)
```

Then pass it to Passage during configuration:

```swift
app.passage.configure(
    services: .init(
        emailDelivery: emailDelivery,
        // ... other services
    ),
    configuration: .init(/* ... */)
)
```

## Mailgun Templates

This package uses [Mailgun Templates](https://documentation.mailgun.com/en/latest/api-sending-messages.html#templates) for email rendering. You need to create the following templates in your Mailgun dashboard:

| Email Type | Default Template Name | Template Variables |
|------------|----------------------|-------------------|
| Email Verification | `email-verification` | `verify_url`, `verify_code`, `email`, `username` |
| Password Reset | `password-reset` | `reset_url`, `reset_code`, `email`, `username` |
| Welcome | `welcome` | `email`, `username` |
| Verification Confirmation | `verification-confirmation` | `email`, `username` |
| Magic Link | `magic-link` | `magic_link_url`, `email`, `username` |

### Example Template

Here's an example Mailgun template for email verification:

```html
<h1>Verify your email</h1>
<p>Hi {{username}},</p>
<p>Please verify your email address by clicking the link below:</p>
<p><a href="{{verify_url}}">Verify Email</a></p>
<p>Or enter this code: <strong>{{verify_code}}</strong></p>
```

## Custom Messages

You can customize the subject lines and template names for each email type:

```swift
let emailDelivery = MailgunEmailDelivery(
    app: app,
    configuration: .init(
        mailgun: .init(
            apiKey: "your-api-key",
            defaultDomain: .init("mail.yourdomain.com", .us)
        ),
        sender: .init(email: "noreply@yourdomain.com"),
        messages: .init(
            verification: .init(
                subject: "Please verify your email",
                template: "custom-verification-template"
            ),
            passwordReset: .init(
                subject: "Password reset requested",
                template: "custom-reset-template"
            ),
            welcome: .init(
                subject: "Welcome to Our App!",
                template: "custom-welcome-template"
            ),
            verificationConfirmation: .init(
                subject: "Your email has been verified",
                template: "custom-confirmation-template"
            ),
            magicLink: .init(
                subject: "Sign in to Your App",
                template: "custom-magic-link-template"
            )
        )
    )
)
```

## Requirements

- Swift 6.2+
- macOS 15+ / Linux
- Vapor 4.119+

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
