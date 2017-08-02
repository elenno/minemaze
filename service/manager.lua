local skynet = require "skynet"
local service = require "service"
local log = require "log"

local manager = {}
local users = {}
local client_map = {}

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

function manager.bind_client(fd, client)
	log("manager.bind_client fd:%d client:%s", fd, client)

	client_map[fd] = client
end

function manager.unbind_client(fd)
	client_map[fd] = nil
end

function manager.push_proto(fd, t, data)
	log("manager.push_proto fd:%d", fd)

	if -1 == fd then
		return
	end

	if not client_map[fd] then
		return
	end

	log("manager.push_proto client.push fd:%d", fd)
	local client = client_map[fd]
	client.push(client, t, data)
end

service.init {
	command = manager,
	info = users,
}


