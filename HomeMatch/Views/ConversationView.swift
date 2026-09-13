import SwiftUI

struct ConversationView: View {
    let name: String
    let matchPercentage: Int

    @Environment(\.dismiss) private var dismiss
    @State private var draftMessage = ""

    private var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }

    private var initials: String {
        name.split(separator: " ").compactMap(\.first).prefix(2).map(String.init).joined()
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 16) {
                    datePill

                    receivedMessage(
                        "Hi Emily! We matched at 92% — I saw you're also looking around Ultimo for September. Are you still searching?",
                        timestamp: "4:32 pm"
                    )

                    sentMessage(timestamp: "4:36 pm · Read") {
                        Text("Hi Priya! Yes — my budget tops out at $420/week including bills. I've been looking at a terrace in Redfern, 12 min to UTS.")
                            .font(.system(size: 15))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                    }

                    sentMessage(timestamp: "4:37 pm · Shared listing") {
                        sharedListingContent
                    }

                    receivedMessage(
                        "Looks great, and the light rail works for my campus days. I've booked a viewing for Wed 9 Sept at 12:30 — want to come along together?",
                        timestamp: "4:41 pm"
                    )

                    typingIndicator
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }

            inputBar
        }
        .background(DesignTokens.pageBackground)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DesignTokens.primary)
                    .frame(width: 28, height: 36)
            }
            .buttonStyle(.plain)

            InitialsAvatar(initials: initials, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DesignTokens.textPrimary)
                Text("\(matchPercentage)% match · active 20 min ago")
                    .font(.system(size: 12.5))
                    .foregroundStyle(DesignTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(DesignTokens.cardBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DesignTokens.divider.opacity(0.5))
                .frame(height: 1)
        }
    }

    // MARK: - Messages

    private var datePill: some View {
        Text("Today 4:32 pm")
            .font(.system(size: 11.5, weight: .semibold))
            .foregroundStyle(DesignTokens.textBody)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(DesignTokens.tagBackground)
            .clipShape(Capsule())
            .frame(maxWidth: .infinity)
    }

    private func receivedMessage(_ text: String, timestamp: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(DesignTokens.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(DesignTokens.cardBackground)
                .clipShape(BubbleShape.received)
                .cardShadow()
            timestampLabel(timestamp)
        }
        .padding(.trailing, 56)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sentMessage<Content: View>(timestamp: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            content()
                .background(DesignTokens.primary)
                .clipShape(BubbleShape.sent)
            timestampLabel(timestamp)
        }
        .padding(.leading, 56)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var sharedListingContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                StripedPhotoPlaceholder(height: 110)
                    .overlay(alignment: .topLeading) {
                        MatchBadge(percentage: 94)
                            .padding(8)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text("$450/week")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(DesignTokens.textPrimary)
                    Text("42 Turner St, Redfern NSW 2016")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(DesignTokens.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Private room · 3-bed terrace · 12 min to UTS")
                        .font(.system(size: 12.5))
                        .foregroundStyle(DesignTokens.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Rectangle()
                        .fill(DesignTokens.divider.opacity(0.5))
                        .frame(height: 1)
                        .padding(.vertical, 6)

                    Text("Open listing")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(DesignTokens.primary)
                }
                .padding(12)
            }
            .background(DesignTokens.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("This is the one — what do you think?")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
        }
        .padding(6)
    }

    private var typingIndicator: some View {
        HStack(spacing: 5) {
            Circle().frame(width: 6, height: 6).opacity(0.35)
            Circle().frame(width: 7, height: 7).opacity(0.6)
            Circle().frame(width: 8, height: 8).opacity(0.9)
        }
        .foregroundStyle(DesignTokens.textSecondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(DesignTokens.cardBackground)
        .clipShape(BubbleShape.received)
        .cardShadow()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func timestampLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11.5))
            .foregroundStyle(DesignTokens.textSecondary)
            .padding(.horizontal, 4)
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            Button {
                // TODO: attach photo
            } label: {
                Image(systemName: "photo")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DesignTokens.primary)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(DesignTokens.divider, lineWidth: 1))
            }
            .buttonStyle(.plain)

            TextField("Message \(firstName)…", text: $draftMessage)
                .font(.system(size: 15))
                .padding(.horizontal, 14)
                .frame(height: 40)
                .background(DesignTokens.pageBackground)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(DesignTokens.divider.opacity(0.6), lineWidth: 1))

            Button {
                // TODO: send message
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(DesignTokens.primary))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(DesignTokens.cardBackground)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(DesignTokens.divider.opacity(0.5))
                .frame(height: 1)
        }
    }
}

// MARK: - Shared pieces

/// Chat bubble with every corner rounded except the one nearest the sender.
private enum BubbleShape {
    static let received = UnevenRoundedRectangle(
        topLeadingRadius: 18, bottomLeadingRadius: 4, bottomTrailingRadius: 18, topTrailingRadius: 18
    )
    static let sent = UnevenRoundedRectangle(
        topLeadingRadius: 18, bottomLeadingRadius: 18, bottomTrailingRadius: 4, topTrailingRadius: 18
    )
}

struct InitialsAvatar: View {
    let initials: String
    let size: CGFloat

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundStyle(DesignTokens.primary)
            .frame(width: size, height: size)
            .background(Circle().fill(DesignTokens.tagBackground))
    }
}

#Preview {
    ConversationView(name: "Priya Raman", matchPercentage: 92)
}
