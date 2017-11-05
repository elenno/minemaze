local skynet = require "skynet"
local service = require "service"
local client = require "client"
local log = require "log"
local mongo_manager = require "mongo_manager"

local auth = {}
local users = {}
local cli = client.handler()
local retcode = require "retcode"
local utils = require "utils"

local SUCC = { ok = true }
local FAIL = { ok = false }

--注册用户
function cli:CSSignup(args)
	--utils.print(args);
	log("signup userid = %s", args.name)
	if users[args.name] then  -- 数据库一开始就load出所有users
		return 0, "SCError", { errorcode = retcode.USER_NAME_ALREADY_BEEN_REGISTERED, errormsg="USER_NAME_ALREADY_BEEN_REGISTERED"}
	else
		users[args.name] = true
		return 0, "SCSignup", { ok = 1, name = args.name }
	end
end

function cli:CSSignin(args)
	log("signin name = %s", args.name)
	if users[args.name] then
		self.userid = args.name
		self.exit = true
		return 0, "SCSignin", { ok = 1, name = args.name}
	else
	--	return 0, "SCSignin", { ok = 1, name = args.name}
		return 0, "SCError", { errorcode=retcode.LOGIN_GUEST_MUST_SIGNUP_FIRST, errormsg="LOGIN_GUEST_MUST_SIGNUP_FIRST" }
	end
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

function auth.load_all_users()
	log("auth.load_all_users.............")
	local users_data = mongo_manager.get_all_data("users", {}, {_id = 0, user_name = 1})
	if users_data then
		for key, value in ipairs(users_data)
			do 
				log("users: " .. value)
				users[value] = true
		end
	end
end

function auth.on_init()
	
		log("auth.on_init...........")
		client.init("proto")
		auth.load_all_users()
	
end

service.init {
	command = auth,
	info = users,
	init = auth.on_init
	--init = client.init "proto",
	--init = auth.load_all_users,
}
