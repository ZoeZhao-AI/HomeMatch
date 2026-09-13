import SwiftUI

struct ConversationView: View {
    let name: String
    let matchPercentage: Int
    let avatarImageName: String?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ConversationViewModel

    @MainActor
    init(recipientID: String, name: String, matchPercentage: Int, avatarImageName: String? = nil) {
        self.name = name
        self.matchPercentage = matchPercentage
        self.avatarImageName = avatarImageName
        _viewModel = StateObject(wrappedValue: ConversationViewModel(recipientID: recipientID, matchPercentage: matchPercentage))
    }

    private static let locale = Locale(identifier: "en_AU")

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
                    if let first = viewModel.messages.first {
                        datePill(for: first.sentAt)
                    }

                    ForEach(viewModel.messages, id: \.messageID) { message in
                        messageRow(message)
                    }

                    typingIndicator
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .defaultScrollAnchor(.bottom)

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

            if let avatarImageName {
                PhotoOrPlaceholder(avatarImageName, size: 40, cornerRadius: 20)
            } else {
                InitialsAvatar(initials: initials, size: 40)
            }

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

    private func datePill(for date: Date) -> some View {
        let time = timeLabel(date)
        let label = Calendar.current.isDateInToday(date)
            ? "Today \(time)"
            : "\(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(Self.locale))) \(time)"
        return Text(label)
            .font(.system(size: 11.5, weight: .semibold))
            .foregroundStyle(DesignTokens.textBody)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(DesignTokens.tagBackground)
            .clipShape(Capsule())
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func messageRow(_ message: Message) -> some View {
        let isSent = message.senderID == viewModel.currentUserID
        let timestamp = message.sharedListingID == nil
            ? timeLabel(message.sentAt)
            : "\(timeLabel(message.sentAt)) · Shared listing"

        if isSent {
            sentMessage(timestamp: timestamp) {
                if let sharedListingID = message.sharedListingID {
                    sharedListingContent(listingID: sharedListingID, caption: message.content)
                } else {
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                }
            }
        } else {
            receivedMessage(message.content, timestamp: timestamp)
        }
    }

    /// e.g. "4:32 pm"
    private func timeLabel(_ date: Date) -> String {
        date.formatted(.dateTime.hour().minute().locale(Self.locale))
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

    private func sharedListingContent(listingID: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let listing = viewModel.sharedListing(withID: listingID) {
                VStack(alignment: .leading, spacing: 0) {
                    PhotoOrPlaceholder(listing.photoName, height: 110)
                        .overlay(alignment: .topLeading) {
                            MatchBadge(percentage: listing.matchPercentage)
                                .padding(8)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("$\(listing.weeklyRent)/week")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(DesignTokens.textPrimary)
                        Text(listing.address)
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundStyle(DesignTokens.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(sharedListingSummary(listing))
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
            } else {
                Text("This listing is no longer available.")
                    .font(.system(size: 13.5))
                    .foregroundStyle(DesignTokens.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(DesignTokens.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Text(caption)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
        }
        .padding(6)
    }

    /// e.g. "Private Room · Min. 12 months · Furnished"
    private func sharedListingSummary(_ listing: ListingCardData) -> String {
        var parts = [listing.roomTypeLabel, "Min. \(listing.minStayMonths) months"]
        if listing.isFurnished { parts.append("Furnished") }
        if listing.isPetFriendly { parts.append("Pet-friendly") }
        return parts.joined(separator: " · ")
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
        VStack(alignment: .leading, spacing: 8) {
            if let error = viewModel.sendError {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(error.errorDescription ?? "Your message couldn't be sent. Please try again.")
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.system(size: 13))
                .foregroundStyle(DesignTokens.errorBorder)
            }

            inputRow
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

    private var inputRow: some View {
        HStack(spacing: 10) {
            Button {
                // Not functional yet: sharing/attachments aren't wired to real listings.
            } label: {
                Image(systemName: "photo")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DesignTokens.primary)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(DesignTokens.divider, lineWidth: 1))
            }
            .buttonStyle(.plain)

            TextField("Message \(firstName)…", text: $viewModel.draft)
                .font(.system(size: 15))
                .padding(.horizontal, 14)
                .frame(height: 40)
                .background(DesignTokens.pageBackground)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(DesignTokens.divider.opacity(0.6), lineWidth: 1))
                .submitLabel(.send)
                .onSubmit { viewModel.send() }

            Button {
                viewModel.send()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(viewModel.canSend ? Color.white : DesignTokens.disabledText)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(viewModel.canSend ? DesignTokens.primary : DesignTokens.disabledBackground))
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canSend)
            .accessibilityLabel("Send")
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
    ConversationView(recipientID: "priya", name: "Priya Raman", matchPercentage: 93, avatarImageName: "avatarPriya")
}
