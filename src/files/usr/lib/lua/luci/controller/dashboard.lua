module("luci.controller.dashboard", package.seeall)

function index()
    entry({"admin", "services", "neighborlink_dashboard"}, template("nlink/dashboard"), _("NeighborLink Dashboard"), 89)
end
