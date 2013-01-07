async = require('async')
express = require('express')
expressError = require('express-error')
fs = require('fs')
kue = require('kue')
mongodb = require('mongodb')

# load config
config = JSON.parse(fs.readFileSync('config.json', 'utf8'))

# connect to MongoDB
mongo = {}
mongo.server = new mongodb.Server(config.mongodb.host, config.mongodb.port,
    auto_reconnect: true
)
mongo.db = new mongodb.Db(config.mongodb.db, mongo.server,
    journal: true
)

# Create job queue
jobs = kue.createQueue()

# Set up express.js
app = express()
app.configure ->
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static __dirname + '/public'

app.configure 'development', ->
    # Only show exceptions in development mode
    app.use expressError.express3(
        contextLinesCount: 3
        handleUncaughtException: true
    )

app.configure 'production', ->
    app.use express.errorHandler()

app.get '/', (req, res) ->
    res.render 'index'
        title: 'Songride'

app.get '/stats', (req, res) ->
    res.render 'stats-form.jade',
        title: 'Statistics'

app.get '/lastfm/:user', (req, res) ->
    # As Last.fm does not care about username captialization
    # we always use the lowercase variant as an identifier
    username = req.params.user.toLowerCase()
    async.waterfall [
        (cb) ->
            mongo.db.open cb
        (db, cb) ->
            db.collection 'users', cb
        (collection, cb) ->
            collection.find(username: username).toArray cb
        (user, cb) ->
            if user.length > 0
                # TODO: update user stats after X days 
                cb null, user: user[0], queued: false
            else
                # no entry for this user was found, so add a job to the queue
                # to generate statistics for him
                jobs.create('lastfm-top50',
                    title: 'Calculate TOP 50 Last.fm statistics for ' + req.params.user
                    username: username
                ).save()
                cb null, queued: true, user: null
    ], (err, result) ->
        mongo.db.close()
        if err?
            console.log(err)
            res.render 'stats-error.jade',
                title: 'An error occured'
        else
            if result.user?
                res.render 'stats-lastfm.jade',
                    username: req.params.user
                    title: 'Last.FM Statistics for ' + req.params.user
                    countries: result.user.countries
            else
                res.render 'stats-queued.jade',
                    title: 'In the queue'

# Running on Port 3000
app.listen(3000)
