mongo = require 'mongodb'

server = new mongo.Server "127.0.0.1", 27117, {}
client = new mongo.Db "songride", server

exports.registerUser = (username) ->
    client.open (err, database) ->
        client.collection 'users', (err, collection) ->
            collection.find( username: username ).nextObject (err, result) ->
                if err?
                    # TODO Send this via mail to the developers
                    console.log(err)
                else if result?
                    collection.update({_id: result._id}, {wants_statistics: true})
                else
                    collection.insert({username: username, wants_statistics: true})
