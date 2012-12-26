async = require('async')
echonest = require('echonest')
fs = require('fs')
kue = require('kue')
LastFmNode = require('lastfm').LastFmNode
mongodb = require('mongodb')

# load config
config = JSON.parse(fs.readFileSync('config.json', 'utf8'))

# Setup Last.FM API endpoint
lastfm = new LastFmNode
    api_key: config.lastfm.api_key
    secret: config.lastfm.secret

# connect to MongoDB
mongo = {}
mongo.server = new mongodb.Server(config.mongodb.host, config.mongodb.port,
    auto_reconnect: true
)
mongo.db_connector = new mongodb.Db(config.mongodb.db, mongo.server,
    journal: true
)

# Setup echonest API endpoint
nest = new echonest.Echonest
    api_key: config.echonest.api_key
    rate_limit: 3000 # Pause 3s between 2 requests

# Create job queue
jobs = kue.createQueue()
async.waterfall [
    (cb) ->
        mongo.db_connector.open cb
    (db, cb) ->
        artist_collection = new mongodb.Collection(db, 'artists')
        user_collection = new mongodb.Collection(db, 'users')

        lastfmArtist2Location = (item, icb) ->
            # Check if we have cached the location
            artist_collection.find(name: item.name).toArray (err, result) ->
                if err?
                    icb err
                else
                    if result.length > 0
                        # TODO: Cache should be refreshed after some time
                        splits = result[0].location.split(',')
                        location = splits[splits.length - 1].trim()
                        if config.songride.corrections[location]?
                            location = config.songride.corrections[location]
                        icb null, [location, parseInt(result[0].playcount)]
                    else
                        # Nothing cached so we need to ask the echonest.
                        req = bucket: "artist_location", name: item.name
                        nest.artist.profile req, (err, res) ->
                            if err?
                                icb err
                            else
                                doc = {}
                                doc.playcount = parseInt(item.playcount)
                                doc.mbid = item.mbid
                                doc.name = item.name
                                doc.updated_at = parseInt(new Date().getTime() / 1000)
                                if res.status.code == 0 and res.artist? and res.artist.artist_location?
                                    doc.location = res.artist.artist_location.location
                                else
                                    doc.location = 'Unknown'
                                console.log(doc.location)
                                # Store the result we got from the echonest
                                # as we do not want to ask them contiously
                                # the same thing.
                                # TODO: If we are updating, use update
                                splits = doc.location.split(',')
                                location = splits[splits.length - 1].trim()
                                if config.songride.corrections[location]?
                                    location = config.songride.corrections[location]
                                artist_collection.insert doc, journal: true, (err, result) ->
                                    icb err, [location, doc.playcount]

        reduceLocationCount = (memo, item, cb) ->
            if memo[item[0]]?
                memo[item[0]] += item[1]
            else
                memo[item[0]] = item[1]
            cb null, memo

        jobs.process 'lastfm-top50', (job, done) ->
            async.waterfall [
                (cb) ->
                    # Get the users top50 artists
                    # TODO: Cache result
                    lastfm.request 'user.getTopArtists',
                        user: job.data.username
                        period: 'overall'
                        handlers:
                            success: (data) -> cb null, data
                            error: cb
                (data, cb) ->
                    job.progress(10, 100)
                    cb null, data.topartists.artist
                (artists, cb) ->
                    # Get the artists country
                    async.mapSeries artists, lastfmArtist2Location, cb
                (artists, cb) ->
                    job.progress(80, 100)
                    async.reduce artists, {}, reduceLocationCount, cb
                (countries, cb) ->
                    job.progress(90, 100)
                    # Save result into the database
                    doc = {}
                    doc.username = job.data.username
                    doc.updated_at = parseInt(new Date().getTime() / 1000)
                    doc.countries = countries
                    user_collection.insert doc, journal: true, cb
            ], (err, result) ->
                job.progress(100, 100)
                if err?
                    done(err)
                else
                    done()
], (err, db) ->
    mongo.db_connector.close()
