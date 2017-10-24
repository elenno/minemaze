local skynet = require "skynet"
local service = require "service"
local client = require "client"
local log = require "log"

local auth = {}
local users = {}
local cli = client.handler()
local retcode = require "retcode"
local utils = require "utils"

local SUCC = { ok = true }
local FAIL = { ok = false }

function cli:signup(args)
	utils.print(args);
	log("signup userid = %s", args.userid)
	if users[args.userid] then
		return FAIL
	else
		users[args.userid] = true
		return SUCC
	end
end

function cli:CSSignin(args)
	log("signin name = %s", args.name)
	--if users[args.name] then
		self.userid = args.name
		self.exit = true
		return 0, "SCSignin", { ok = 1, name = args.name}
	--else
	--	return 0, "SCError", { errorcode=retcode.UNKNOWN_ERROR, errormsg="unknown error" }
	--end
end

function cli:test(args)
	log("test args %d %d %s %d", args.param1, args.param2, args.param3, args.param4)
	--local data = {player_id = 1, player_name = "test123"}
	--local key = {player_id = 1}
	--mongo_manager.save_data("player", key, data)

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
