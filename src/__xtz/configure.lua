local user = am.app.get("user")
ami_assert(type(user) == "string", "User not specified...", EXIT_INVALID_CONFIGURATION)

local ok, error = fs.mkdirp("data")
ami_assert(ok, "failed to create data directory: ".. tostring(error))
local uid, err = fs.getuid(user)
ami_assert(uid, "failed to get " .. user .. "uid - " .. tostring(err))

log_info("configuring " .. am.app.get("id") .. " services...")

local service_manager = require"__xtz.service-manager"
local services = require"__xtz.services"

service_manager.remove_services(services.cleanup_names)
service_manager.install_services(services.active)

log_success(am.app.get("id") .. " services configured")

local CONFIG_FILE_DIRECTORY = "./data/.tezos-dal-node"
local CONFIG_FILE_PATH = CONFIG_FILE_DIRECTORY .. "/config.json"

local config_file = am.app.get_configuration("CONFIG_FILE")
if type(config_file) == "table" and not table.is_array(config_file) then
	fs.mkdirp(CONFIG_FILE_DIRECTORY)
	log_info("Creating config file...")
	fs.write_file(CONFIG_FILE_PATH, hjson.stringify_to_json(config_file))
elseif fs.exists("./__xtz/dal-node-config.json") then
	fs.mkdirp(CONFIG_FILE_DIRECTORY)
	fs.copy_file("./__xtz/dal-node-config.json", CONFIG_FILE_PATH)
end

-- prism
local PRISM = am.app.get_configuration("PRISM")
if PRISM then
	require"__xtz.prism.setup"
end

-- finalize
local ok, error = fs.chown(os.cwd() or ".", uid, uid, {recurse = true})
ami_assert(ok, "Failed to chown data - " .. (error or ""))