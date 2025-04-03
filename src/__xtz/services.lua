local app_id = am.app.get("id")

local possible_residue = {
}

local dal_services = {
	[app_id .. "-xtz-dal"] = am.app.get_configuration("NODE_SERVICE_FILE", "__xtz/assets/dal")
}
local prism_services = {
	[app_id .. "-xtz-prism-server"] = "__xtz/assets/prism"
}

local dal_binaries = { "dal-node" }


local dal_node_service_names = {}
for k, _ in pairs(dal_services) do
	dal_node_service_names[k:sub((#(app_id .. "-xtz-") + 1))] = k
end
local prism_service_names = {}
for k, _ in pairs(prism_services) do
	prism_service_names[k:sub((#(app_id .. "-xtz-") + 1))] = k
end

local all = util.clone(dal_services)
local all_names = util.clone(dal_node_service_names)
local all_binaries = util.clone(dal_binaries)

local uses_prism = am.app.get_configuration("PRISM")
if uses_prism then
	for k, v in pairs(prism_service_names) do
		all_names[k] = v
	end
	for k, v in pairs(prism_services) do
		all[k] = v
	end
	table.insert(all_binaries, "prism")
end

-- includes potential residues
local function remove_all_services()
	local service_manager = require"__xtz.service-manager"

	local all = util.merge_arrays(table.values(dal_node_service_names), table.values(prism_service_names))
	all = util.merge_arrays(all or {}, possible_residue)

	for _, service in ipairs(all or {}) do
		if type(service) ~= "string" then goto CONTINUE end
		log_debug("Removing service " .. service)
		local ok, err = service_manager.safe_remove_service(service)
		if not ok then
			ami_error("Failed to remove " .. service .. ": " .. (err or ""))
		end
		::CONTINUE::
	end
end

return {
	all = all,
	all_names = all_names,
	all_binaries = all_binaries,
	remove_all_services = remove_all_services
}