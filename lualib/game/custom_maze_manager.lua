local player_manager = require("player_manager")
local custom_maze_manager = {}
local custom_maze_map = {}
local mongo_manager = require("mongo_manager")
local maze_info_map = {}

function custom_maze_manager.get_player_custom_maze(player_id) 
	if not custom_maze_map[player_id] then 
		--从数据库取数据到缓存
		local custom_maze = mongo_manager.get_data("custom_maze", {player_id = player_id})
		if custom_maze then
			custom_maze_map[player_id] = custom_maze
		else
			--todo 暂时填简单的数据
			local custom_maze_tmp = {}
			custom_maze_tmp.player_id = player_id
			custom_maze_tmp.custom_maze_list = {}
			
			custom_maze_map[player_id] = custom_maze_tmp
		end
		
	end
		
	return custom_maze_map[player_id]
end

function custom_maze_manager.get_maze_info(maze_id)
	if not maze_info_map[maze_id] then
		--从数据库取数据到缓存
		local maze_info = mongo_manager.get("maze_info", {maze_id = maze_id})
		if maze_info then
			maze_info_map[maze_id] = maze_info
		else
			return nil
	end

	return maze_info_map[maze_id]
end

function custom_maze_manager.save_player_custom_maze(player_id, custom_maze)
	custom_maze_map[player_id] = custom_maze
	mongo_manager.save_data("custom_maze", {player_id = player_id}, custom_maze)
end

function custom_maze_manager.save_maze_info(maze_id, maze_info)
	maze_info_map[maze_id] = maze_info
	mongo_manager.save_data("maze_info", {maze_id = maze_id}, maze_info)	
end

function custom_maze_manager.add_custom_maze(player_id, maze_id)
	local custom_maze = custom_maze_manager.get_player_custom_maze(player_id)
	local is_found = false
	for i = 1, #custom_maze.custom_maze_list do
		if maze_id == custom_maze.custom_maze_list[i] then
			is_found = true
		end
	end

	if not is_found then
		table.insert(custom_maze.custom_maze_list, #custom_maze.custom_maze_list + 1, maze_id)
		custom_maze_manager.save_player_custom_maze(player_id, custom_maze);
	end
end

function custom_maze_manager.create_custom_maze(player_id, maze_info)
	local maze_id = mongo_manager.get_data_count("custom_maze", {})
	maze_info["maze_id"] = maze_id
	maze_info["player_id"] = player_id
	custom_maze_manager.add_custom_maze(player_id, maze_id)
	local player_custom_maze = custom_maze_manager.get_player_custom_maze(player_id)
	custom_maze_manager.save_player_custom_maze(player_id, player_custom_maze) --保存到玩家自定义迷宫列表
	custom_maze_manager.save_maze_info(maze_id, maze_info)	--保存自定义迷宫
end

return custom_maze_manager