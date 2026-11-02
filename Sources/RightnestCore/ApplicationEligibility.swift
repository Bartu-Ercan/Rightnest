public enum ApplicationEligibility {
    public static func allows(bundleID: String?, isRegular: Bool, ownBundleID: String,
                              disabled: Set<String>) -> Bool {
        guard isRegular, let bundleID, !bundleID.isEmpty, bundleID != ownBundleID else { return false }
        return !disabled.contains(bundleID)
    }
}
