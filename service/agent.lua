local skynet = require "skynet"
local service = require "service"
local client = require "client"
local log = require "log"
local protobuf = require "protobuf"

local pb_files = {
    "./proto/Person.pb",
	"./proto/pbhead.pb",
}

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

	--for _,v in ipairs(pb_files) do
    --    protobuf.register_file(v)
    --end

	--protobuf.register_file "./proto/Person.pb"

	--local msg = {name = "linlin"}
    --log("encode proto!!!!!!!!")
    --local data = protobuf.encode("Person", msg)
    --log("decode proto")
    --local de_msg = protobuf.decode("Person", data)
    --log(de_msg.name)	

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
	skynet.call(service.player_manager, "lua", "on_login", TEST_PLAYER_ID, self.fd)

	--log("player_info  name:%s ", player_info.player_name)
	--todo push 
	--if player_info then
	--	client.push(self, "player_info", {
	--	player_name = player_info.player_name or "",
	--	story_record = player_info.story_record or 0,
	--	challenging_maze_type = player_info.challenging_maze_type or 0,
	--	challenging_maze_id = player_info.challenging_maze_id or 0,
	--	face_direction = player_info.face_direction or 0,
	--	cur_pos_x = player_info.cur_pos_x or 0,
	--	cur_pos_y = player_info.cur_pos_y or 0
	--	})
	--end

	--TODO test
	--math.randomseed(os.time())
	--custom_maze_manager.add_custom_maze(TEST_PLAYER_ID, math.random(1000))

	return { ok = true }
end

function cli:upload_maze(args)
	local maze_info = {}

	--todo 检查参数合法性 字符串要检查敏感字

	maze_info.maze_name = args.maze_name
	maze_info.maze_height = args.maze_height
	maze_info.maze_width = args.maze_width
	maze_info.maze_map = args.maze_map
	maze_info.start_pos_x = args.start_pos_x
	maze_info.start_pos_y = args.start_pos_y
	maze_info.end_pos_x = args.end_pos_x
	maze_info.end_pos_y = args.end_pos_y
	maze_info.head_line = args.head_line
	maze_info.head_line_remark = args.head_line_remark
	maze_info.maze_setting_flag = args.maze_setting_flag

	skynet.call(service.custom_maze_manager, "lua", "create_custom_maze", TEST_PLAYER_ID, maze_info)

	return { ok = true }
end

function cli:start_challenge(args)
	local maze_type = args.maze_type
	local maze_id = args.maze_type

	skynet.call(service.player_manager, "lua", "start_challenge", TEST_PLAYER_ID, maze_type, maze_id)

	return { ok = true }
end

function cli:finish_challenge(args)
	local maze_type = args.maze_type
	local maze_id = args.maze_id

	skynet.call(service.player_manager, "lua", "finish_challenge", TEST_PLAYER_ID, maze_type, maze_id)

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

