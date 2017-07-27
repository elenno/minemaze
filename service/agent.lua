local skynet = require "skynet"
local service = require "service"
local client = require "client"
local log = require "log"

local agent = {}
local data = {}
local cli = client.handler()

TEST_PLAYER_ID = 1  --todo 测试用player_id

function cli:ping()
	if not self.login then
		log("ping() not login yet")
	end
	log "ping"
end

function cli:login()
	assert(not self.login)
	if data.fd then
		log("login fail %s fd=%d", data.userid, self.fd)
		return { ok = false }
	end
	data.fd = self.fd
	self.login = true
	log("login succ %s fd=%d", data.userid, self.fd)
	client.push(self, "push", { text = "welcome" })	-- push message to client

	--local player_manager = skynet.uniqueservice "player_manager"
	local player_info = skynet.call(service.player_manager, "lua", "on_login", TEST_PLAYER_ID)

	log("player_info  name:%s ", player_info.player_name)
	--todo push 
	if player_info then
		client.push(self, "player_info", {
			player_name = player_info.player_name or "",
		story_record = player_info.story_record or 0,
		challenging_maze_type = player_info.challenging_maze_type or 0,
		challenging_maze_id = player_info.challenging_maze_id or 0,
		face_direction = player_info.face_direction or 0
		})
	end

	--player_manager.on_login(TEST_PLAYER_ID)

	--TODO test
	--math.randomseed(os.time())
	--custom_maze_manager.add_custom_maze(TEST_PLAYER_ID, math.random(1000))

	return { ok = true }
end

local function new_user(fd)
	local ok, error = pcall(client.dispatch , { fd = fd })
	log("fd=%d is gone. error = %s", fd, error)
	client.close(fd)
	log("new user close !!!!!!!")
	if data.fd == fd then
		data.fd = nil
		skynet.sleep(1000)	-- exit after 10s
		if data.fd == nil then
			-- double check
			if not data.exit then
				data.exit = true	-- mark exit
				skynet.call(service.manager, "lua", "exit", data.userid)	-- report exit
				log("user %s afk", data.userid)
				skynet.exit()
			end
		end
	end
end

function agent.assign(fd, userid)
	if data.exit then
		return false
	end
	if data.userid == nil then
		data.userid = userid
	end
	assert(data.userid == userid)
	skynet.fork(new_user, fd)
	return true
end

service.init {
	command = agent,
	info = data,
	require = {
		"manager",
		"player_manager"
	},
	init = client.init "proto",
}

