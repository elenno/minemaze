--todo read config
local mongo = require "mongo"
local bson = require "bson"
local host = "127.0.0.1"
local db_name = "minemaze"
local mongo_manager = {}

function mongo_manager.test_insert_with_index()
	local db = mongo.client({host = host})

	db[db_name].testdb:dropIndex("*")
	db[db_name].testdb:drop()

	db[db_name].testdb:ensureIndex({test_key = 1}, {unique = true, name = "test_key_index"})

	local ret = db[db_name].testdb:safe_insert({test_key = 1})
	assert(ret and ret.n == 1)

	local ret = db[db_name].testdb:safe_insert({test_key = 1})
	assert(ret and ret.n == 0)
end

function mongo_manager.get_mongo_client()
	return mongo.client({host = host})
end

function mongo_manager.save_data(collection, key, data)
	local db = mongo_manager.get_mongo_client()
	db[db_name][collection]:update(key, data, true, false) -- upsert yes, multi no
end

function mongo_manager.get_data(collection, query)
	local db = mongo_manager.get_mongo_client()
	local ret = db[db_name][collection]:findOne(query, {})
	if ret then
		ret['_id'] = nil
		return ret
	else
		return nil
	end
end

function mongo_manager.get_all_data(collection, query, field_selector)
	local db = mongo_manager.get_mongo_client()
	local ret = db[db_name][collection]:find(query, field_selector)
	if ret then
		return ret
	else
		return nil
	end
end

function mongo_manager.ensure_index(collection, index)
	local db = mongo_manager.get_mongo_client()
	db[db_name][collection]:ensureIndex(index, {})
end

function mongo_manager.get_data_count(collection, query)
	local db = mongo_manager.get_mongo_client()
	local ret = db[db_name][collection]:find(query, {})
	return ret:count()
end

return mongo_manager