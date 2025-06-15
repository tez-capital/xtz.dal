local service_manager = require"__xtz.service-manager"
local services = require"__xtz.services"

service_manager.remove_services(services.cleanup_names)

log_success("Node services successfully removed.")