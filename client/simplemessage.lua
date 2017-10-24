local socket = require "simplesocket"
--local sproto = require "sproto"
local utils = require "utils"
local protobuf = require "protobuf"

local message = {}
local var = {
	session_id = 0 ,
	session = {},
	object = {},
}

local pb_files = {
	"./proto/Person.pb",
	"./proto/pbhead.pb",
}

function message.register()
	message.init()
	--local f = assert(io.open(name .. ".s2c.sproto"))
	--local t = f:read "a"
	--f:close()
	--var.host = sproto.parse(t):host "package"
	--local f = assert(io.open(name .. ".c2s.sproto"))
	--local t = f:read "a"
	--f:close()
	--var.request = var.host:attach(sproto.parse(t))
end

function message.init()
	for _,v in ipairs(pb_files) do
		utils.print(protobuf.register_file(v))
	end
end

function message.encode(msg_name, msg)
	utils.print(msg_name)
	utils.print(msg)
	return protobuf.encode(msg_name, msg)
end

function message.decode(msg_name, data)
	utils.print("decode ".. msg_name.. " " .. type(data) .." " .. #data)
	return protobuf.decode(msg_name, data)
end

function message.pack(ret, name, msg)
	--pb协议头
    local ret = ret or 0
    local msg_head = {
        msgtype = 2,
        msgname = name,
        msgret = ret
    }
    local buf_head = message.encode("PbHead.MsgHead", msg_head)

    print("+++++++++++++++pack")
    utils.print(msg_head)
    utils.print(msg)

    --pb协议数据
    local len
    local pack
    if ret == 0 then
        local buf_body = message.encode(name, msg)
        len = 2 + #buf_head + 2 + #buf_body + 1
        pack = string.pack(">Hs2s2c1", len, buf_head, buf_body, 't')
    else
        --返回码不为0时，只下发pb协议头
        len = 2 + #buf_head + 1
        pack = string.pack(">Hs2s1", len, buf_head, 't')
    end
    
	utils.print(pack)
    return pack
end

function message.unpack(data)
    utils.print("---------------Unpack, data=  " .. data)
    local ch_end, buf_head, buf_body = string.unpack(">Hs2s2c1", data)
	utils.print("string.unpack...", buf_head, buf_body, ch_end)
    local msg_head = message.decode("PbHead.MsgHead", buf_head)
    local msg_body = message.decode(msg_head.msgname, buf_body)
    utils.print(msg_head)
    utils.print(msg_body)
	utils.print("---------------Unpack done!!! return:" .. msg_head.msgname, msg_body, "!!!!!")
    return msg_head.msgname, msg_body
end

function message.peer(addr, port)
	var.addr = addr
	var.port = port
end

function message.connect()
	socket.connect(var.addr, var.port)
	socket.isconnect()
end

function message.bind(obj, handler)
	var.object[obj] = handler
end

function message.request(name, args)
	var.session_id = var.session_id + 1
	var.session[var.session_id] = { name = name, req = args }
	--socket.write(var.request(name , args, var.session_id))
	socket.write(message.pack(0, name, args))
	return var.session_id
end

function message.update(ti)
	local msg = socket.read(ti)
	if not msg then
		return false
	end
	utils.print(msg)
	local name, args = message.unpack(msg)

	for obj, handler in pairs(var.object) do
		local f = handler[name]
		if f then
			local ok, err_msg = pcall(f, obj, args)
			if not ok then
	 			print(string.format("push %s for [%s] error : %s", name, tostring(obj), err_msg))
			end
		else
			print("function name:%s not found!", name)
		end	
	end
	

	--local t, session_id, resp, err = var.host:dispatch(msg)
	-- if t == "REQUEST" then
	-- 	for obj, handler in pairs(var.object) do
	-- 		local f = handler[session_id]	-- session_id is request type
	-- 		if f then
	-- 			local ok, err_msg = pcall(f, obj, resp)	-- resp is content of push
	-- 			if not ok then
	-- 				print(string.format("push %s for [%s] error : %s", session_id, tostring(obj), err_msg))
	-- 			end
	-- 		end
	-- 	end
	-- else
	-- 	local session = var.session[session_id]
	-- 	var.session[session_id] = nil

	-- 	for obj, handler in pairs(var.object) do
	-- 		if err then
	-- 			local f = handler.__error
	-- 			if f then
	-- 				local ok, err_msg = pcall(f, obj, session.name, err, session.req, session_id)
	-- 				if not ok then
	-- 					print(string.format("session %s[%d] error(%s) for [%s] error : %s", session.name, session_id, err, tostring(obj), err_msg))
	-- 				end
	-- 			end
	-- 		else
	-- 			local f = handler[session.name]
	-- 			if f then
	-- 				local ok, err_msg = pcall(f, obj, session.req, resp, session_id)
	-- 				if not ok then
	-- 					print(string.format("session %s[%d] for [%s] error : %s", session.name, session_id, tostring(obj), err_msg))
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- end

	return true
end

return message
