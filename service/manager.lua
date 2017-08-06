local skynet = require "skynet"
local service = require "service"
local log = require "log"

local manager = {}
local users = {}
local client_map = {}
local proxy = require "socket_proxy"
local sprotoloader = require "sprotoloader"

local host
local sender
local is_init = false

function manager.init_manager(name)
	local protoloader = skynet.uniqueservice "protoloader"
	local slot = skynet.call(protoloader, "lua", "index", name .. ".c2s")
	host = sprotoloader.load(slot):host "package"
	local slot2 = skynet.call(protoloader, "lua", "index", name .. ".s2c")
	sender = host:attach(sprotoloader.load(slot2))
	log("BBBBBBBBBBBBBBBBBBBB")
end

local function new_agent()
	-- todo: use a pool
	return skynet.newservice "agent"
end

local function free_agent(agent)
	-- kill agent, todo: put it into a pool maybe better
	skynet.kill(agent)
end

function manager.assign(fd, userid)
	local agent
	repeat
		agent = users[userid]
		if not agent then
			agent = new_agent()
			if not users[userid] then
				-- double check
				users[userid] = agent
			else
				free_agent(agent)
				agent = users[userid]
			end
		end
	until skynet.call(agent, "lua", "assign", fd, userid)
	log("Assign %d to %s [%s]", fd, userid, agent)
end

function manager.exit(userid)
	agent = users[userid]
	log("manager.exit userid:%s  agent:[%s]", userid, agent)
	users[userid] = nil
end

function manager.push_proto(fd, t, data)
	if is_init == false then
		manager.init_manager("proto")
		is_init = true
	end

	log("manager.push_proto fd:%d", fd)

	proxy.write(fd, sender(t, data))
end

function manager.bind_client(fd)
	proxy.subscribe(fd)
end

function manager.unbind_client(fd)
	proxy.close(fd)
end

service.init {
	command = manager,
	info = users,
}


