express = require('express')
trycatch = require('trycatch')
routes  = require('./routes')
register = require('./lib/register')

app = express()

app.configure ->
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static __dirname + '/public'

app.configure 'development', ->
  app.use express.errorHandler
    dumpExceptions: true
    showStack: true

app.configure 'production', ->
    app.use express.errorHandler()

app.get '/', routes.index

app.get '/register', (req, res) ->
    res.render 'register.jade',
        title: 'Register'

app.post '/register', (req, res) ->
    tryFunc = ->
        if req.param('username')
            register.registerUser req.param('username'), ->
                res.render 'register-success.jade',
                    title: 'Register'
        else
            res.render 'register.jade',
                title: 'Register'
    catchFunc = (err) ->
        res.render 'error.jade',
            title: err.message
            error: err
    trycatch(tryFunc, catchFunc)

app.listen(3000)
