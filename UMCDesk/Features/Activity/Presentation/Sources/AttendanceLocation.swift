//  AttendanceLocation.swift
//  ActivityPresentation
//
//  Created by euijjang97 on 11/23/26.
//

import ActivityDomain
import CoreLocation
import Foundation

enum AttendanceLocation {
    /// Matches the attendance geofence in the UMC mobile app.
    static let radius: CLLocationDistance = 50

    enum Failure: LocalizedError {
        case denied, unavailable, outside
        var errorDescription: String? {
            switch self {
            case .denied: "위치 권한을 허용하거나 모바일 앱에서 출석을 요청해 주세요."
            case .unavailable: "현재 위치를 정확히 확인할 수 없어요. 다시 시도하거나 사유를 제출해 주세요."
            case .outside: "일정 장소에서 50m 이내에 도착한 뒤 다시 시도해 주세요."
            }
        }
    }

    static func verify(_ venue: ActivityCoordinate) async throws -> ActivityCoordinate {
        try await withThrowingTaskGroup(of: ActivityCoordinate.self) { group in
            group.addTask {
                try await Task.sleep(for: .seconds(20))
                throw Failure.unavailable
            }
            group.addTask {
                let destination = CLLocation(latitude: venue.latitude, longitude: venue.longitude)
                for try await update in CLLocationUpdate.liveUpdates() {
                    try Task.checkCancellation()
                    if update.authorizationDenied || update.authorizationRestricted {
                        throw Failure.denied
                    }
                    guard let location = update.location,
                        abs(location.timestamp.timeIntervalSinceNow) < 30,
                        (0...radius).contains(location.horizontalAccuracy)
                    else { continue }
                    guard destination.distance(from: location) <= radius else {
                        throw Failure.outside
                    }
                    return ActivityCoordinate(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude)
                }
                throw Failure.unavailable
            }
            defer { group.cancelAll() }
            guard let coordinate = try await group.next() else { throw Failure.unavailable }
            return coordinate
        }
    }
}
