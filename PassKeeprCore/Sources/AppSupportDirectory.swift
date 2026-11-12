import Foundation

public enum AppSupportDirectory {
    public static var url: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    }
}
