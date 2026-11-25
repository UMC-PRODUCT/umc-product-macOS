//
//  MatchingProgressController.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/22/26.
//

import AppKit
import MatchingDomain
import Observation
import SwiftUI

@MainActor
@Observable
final class MatchingProgressController: NSObject {
    private let repository: any MatchingUseCase
    private var accountId: String?
    private var monitor: Task<Void, Never>?
    private var expanded: NSPanel?
    private var revision = UUID()
    var openApplications: (() -> Void)?
    private(set) var card: MatchingApplication?
    private(set) var round: MatchingRound?
    private(set) var lastChecked: Date?
    private(set) var unavailable = false
    private enum Suspension { case computer, displays, session }
    private var suspensions: Set<Suspension> = []
    private var suspended: Bool { !suspensions.isEmpty }
    var isSignedIn: Bool { accountId != nil }

    init(repository: any MatchingUseCase) {
        self.repository = repository
        super.init()
        let workspace = NSWorkspace.shared.notificationCenter
        for notification in [
            NSWorkspace.willSleepNotification, NSWorkspace.didWakeNotification,
            NSWorkspace.screensDidSleepNotification, NSWorkspace.screensDidWakeNotification,
            NSWorkspace.sessionDidResignActiveNotification, NSWorkspace.sessionDidBecomeActiveNotification
        ] {
            workspace.addObserver(self, selector: #selector(activityChanged(_:)),
                                  name: notification, object: nil)
        }
    }

    func setAccount(_ id: String?) {
        guard id != accountId else { return }
        revision = UUID()
        monitor?.cancel()
        monitor = nil
        closeExpanded()
        accountId = id
        card = nil
        round = nil
        lastChecked = nil
        unavailable = false
    }

    func restart() {
        guard expanded != nil, accountId != nil, !suspended else { return }
        monitor?.cancel()
        let ticket = UUID()
        revision = ticket
        monitor = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh(ticket: ticket)
                do { try await Task.sleep(for: .seconds(60)) } catch { return }
            }
        }
    }

    private func refresh(ticket: UUID) async {
        do {
            let gisuId = try await repository.activeGisuId()
            let cards = try await repository.myApplications(gisuId: gisuId, drafts: false)
            // Only resolve schedules for the user's actual cards. Old chapter schedules are
            // returned by this endpoint too, so look up a globally unique round identifier.
            let rounds = cards.isEmpty ? [] : try await repository.rounds(chapterId: nil)
            let byId = Dictionary(rounds.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            guard ticket == revision, !Task.isCancelled else { return }
            card = Self.currentCard(cards, rounds: byId)
            round = card?.matchingRound?.id.flatMap { byId[$0] }
            lastChecked = Date()
            unavailable = false
        } catch {
            guard ticket == revision, !Task.isCancelled else { return }
            unavailable = true
        }
    }

    static func currentCard(
        _ cards: [MatchingApplication], rounds: [String: MatchingRound]
    ) -> MatchingApplication? {
        // A card without an application ID represents actual team membership, even when
        // a legacy assignment has no stored round. Prefer it to prior application decisions.
        let memberships = cards.filter { $0.applicationId == nil && $0.status == "APPROVED" }
        let candidates = memberships.isEmpty ? cards : memberships
        func startsAt(_ card: MatchingApplication) -> Date {
            guard let id = card.matchingRound?.id, let value = rounds[id]?.startsAt else {
                return .distantPast
            }
            return (try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(value))
                ?? (try? Date.ISO8601FormatStyle().parse(value)) ?? .distantPast
        }
        return candidates.max { startsAt($0) < startsAt($1) }
    }

    @objc private func activityChanged(_ notification: Notification) {
        let wasSuspended = suspended
        switch notification.name {
        case NSWorkspace.willSleepNotification: suspensions.insert(.computer)
        case NSWorkspace.didWakeNotification: suspensions.remove(.computer)
        case NSWorkspace.screensDidSleepNotification: suspensions.insert(.displays)
        case NSWorkspace.screensDidWakeNotification: suspensions.remove(.displays)
        case NSWorkspace.sessionDidResignActiveNotification: suspensions.insert(.session)
        case NSWorkspace.sessionDidBecomeActiveNotification: suspensions.remove(.session)
        default: return
        }
        guard wasSuspended != suspended else { return }
        if suspended {
            revision = UUID()
            monitor?.cancel()
            unavailable = true
            closeExpanded()
        } else {
            restart()
        }
    }

    func showExpanded() {
        guard !suspended else { return }
        closeExpanded()
        let pointer = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(pointer) })
                ?? NSScreen.main else { return }
        let width = min(520.0, screen.visibleFrame.width)
        let height = 254.0
        let center = screen.auxiliaryTopLeftArea.flatMap { left in
            screen.auxiliaryTopRightArea.map { (left.maxX + $0.minX) / 2 }
        } ?? pointer.x
        let x = max(screen.visibleFrame.minX, min(center - width / 2, screen.visibleFrame.maxX - width))
        let panel = MatchingDetailPanel(
            contentRect: NSRect(x: x, y: screen.visibleFrame.maxY - height - 4, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false
        )
        panel.onEscape = { [weak self] in self?.closeExpanded() }
        panel.contentView = NSHostingView(rootView: MatchingProgressPanel(controller: self))
        configure(panel)
        expanded = panel
        panel.makeKeyAndOrderFront(nil)
        restart()
    }

    func closeExpanded() {
        revision = UUID()
        monitor?.cancel()
        monitor = nil
        expanded?.orderOut(nil)
        expanded = nil
    }

    private func configure(_ panel: NSPanel) {
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
    }
}

@MainActor
private final class MatchingDetailPanel: NSPanel {
    var onEscape: (() -> Void)?
    override var canBecomeKey: Bool { true }
    override func cancelOperation(_ sender: Any?) { onEscape?() }
}
