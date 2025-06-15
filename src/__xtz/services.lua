local app_id = am.app.get("id")

local possible_residue = {
	app_id .. "-xtz-prism-server"
}

local dal_services = {
	[app_id .. "-xtz-dal"] = am.app.get_configuration("NODE_SERVICE_FILE", "__xtz/assets/dal")
}
local prism_services = {
	[app_id .. "-xtz-prism"] = "__xtz/assets/prism"
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

local active_services = util.clone(dal_services)
local active_names = util.clone(dal_node_service_names)
local wanted_binaries = util.clone(dal_binaries)

local uses_prism = am.app.get_configuration("PRISM")
if uses_prism then
	for k, v in pairs(prism_service_names) do
		active_names[k] = v
	end
	for k, v in pairs(prism_services) do
		active_services[k] = v
	end
	table.insert(wanted_binaries, "prism")
end

---@type string[]
local cleanup_names = {}
cleanup_names = util.merge_arrays(cleanup_names, table.values(dal_node_service_names))
cleanup_names = util.merge_arrays(cleanup_names, table.values(prism_service_names))
cleanup_names = util.merge_arrays(cleanup_names, possible_residue)

return {
	active = active_services,
	active_names = active_names,
	wanted_binaries = wanted_binaries,
	cleanup_names = cleanup_names,
}