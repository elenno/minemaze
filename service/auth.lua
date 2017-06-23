local skynet = require "skynet"
local service = require "service"
local client = require "client"
local log = require "log"
local mongo_manager = require "mongo_manager"
local player_manager = require "player_manager"

local auth = {}
local users = {}
local cli = client.handler()

local SUCC = { ok = true }
local FAIL = { ok = false }

function cli:signup(args)
	log("signup userid = %s", args.userid)
	if users[args.userid] then
		return FAIL
	else
		users[args.userid] = true
		return SUCC
	end
end

function cli:signin(args)
	log("signin userid = %s", args.userid)
	if users[args.userid] then
		self.userid = args.userid
		self.exit = true
		return SUCC
	else
		return FAIL
	end
end

function cli:test(args)
	log("test args %d %d %s %d", args.param1, args.param2, args.param3, args.param4)
	--local data = {player_id = 1, player_name = "test123"}
	--local key = {player_id = 1}
	--mongo_manager.save_data("player", key, data)
	local player = player_manager.get_player(1)
	for k,v in pairs(player) do
    	print(k,v)
	end
	return SUCC
end

function cli:ping()
	log("ping")
end

function auth.shakehand(fd)
	local c = client.dispatch { fd = fd }
	return c.userid
end

service.init {
	command = auth,
	info = users,
	init = client.init "proto",
}
