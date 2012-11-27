mongo = require 'mongodb'

server = new mongo.Server "127.0.0.1", 27117, {}
client = new mongo.Db "songride", server, w:'majority', journal:true

exports.registerUser = (username, success) ->
    client.open (err, database) ->
        client.collection 'users', (err, collection) ->
            collection.find( username: username ).nextObject (err, result) ->
                if err?
                    throw err
                else if result?
                    collection.update({_id: result._id}, {wants_statistics: true})
                else
                    collection.insert({username: username, wants_statistics: true})
                success()
