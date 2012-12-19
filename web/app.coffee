express = require('express')
trycatch = require('trycatch')
routes  = require('./routes')

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

app.get '/stats', (req, res) ->
    res.render 'stats-form.jade',
        title: 'Statistics'

app.listen(3000)
