local needs_json_output = am.options.OUTPUT_FORMAT == "json"

local options = ...
local timeout = 4
if options.timeout then
	timeout = tonumber(options.timeout) or timeout
end

local print_dal_info = options.dal
local print_service_info = options.services
local print_all = (not print_dal_info) and (not print_service_info)

local info = {
	level = "ok",
	status = "dal-node is operational",
	version = am.app.get_version(),
	type = am.app.get_type(),
	services = {}
}

local is_baker = am.app.get_configuration("NODE_TYPE") == "baker"
if is_baker then
	info.status = "XTZ baker is operational"
end

if print_all or print_service_info then
	local service_manager = require"__xtz.service-manager"
	local services = require"__xtz.services"

	local statuses, all_running = service_manager.get_services_status(services.active_names)
	info.services = statuses
	if not all_running then
		info.status = "one or more baker services is not running"
		info.level = "error"
	end
end

-- attesters
local attester_profiles = am.app.get_model("ATTESTER_PROFILES")
if table.is_array(attester_profiles) and #attester_profiles > 0 then
	info.attester_profiles = attester_profiles
end

-- health
local rpc_url = am.app.get_model("LOCAL_RPC_ADDR")
-- {"status":"up","checks":[{"name":"p2p","status":"up"},{"name":"topics","status":"ok"},{"name":"gossipsub","status":"up"}]}
-- 127.0.0.1:10732/health
local rest_client = net.RestClient:new(rpc_url, { timeout = timeout })
if print_all or print_dal_info then
	local response, _ = rest_client:get("health")
	if response then
		local data = response.data
		info.dal_health = data
	else
		info.dal_health = {
			status = "error",
			checks = {}
		}
	end

	if info.dal_health.status ~= "up" then
		info.status = "DAL node is not running"
		info.level = "error"
	end
end

if needs_json_output then
	print(hjson.stringify_to_json(info, { indent = false }))
else
	print(hjson.stringify(info, { sort_keys = true }))
end
