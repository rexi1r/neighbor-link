module("luci.controller.nlink", package.seeall)

function index()
    entry({"admin", "services", "neighborlink"}, firstchild(), _("NeighborLink"), 90)
    entry({"admin", "services", "neighborlink", "settings"}, template("nlink/settings"), _("Settings"), 10)
end
