async  = require 'async'
{exec} = require 'child_process'
util   = require 'util'

task 'update', 'install and update all dependencies', ->
    async.waterfall [
        (cb) ->
            util.log 'Installing new npm components'
            exec 'npm install', (err, stdout, stderr) ->
                cb err, stderr
        (_, cb) ->
            util.log 'Updating npm components'
            exec 'npm update', (err, stdout, stderr) ->
                cb err, stderr
        (_, cb) ->
            util.log 'Installing bower components'
            exec 'bower install', (err, stdout, stderr) ->
                cb err, stderr
        (_, cb) ->
            util.log 'Updating bower components'
            exec 'bower update', (err, stdout, stderr) ->
                cb err, stderr
        (_, cb) ->
            util.log 'Installing bootstrap dependencies'
            exec 'npm install', cwd: 'components/bootstrap', (err, stdout, stderr) ->
                cb err, stderr
        (_, cb) ->
            util.log 'Updating bootstrap dependencies'
            exec 'npm update', cwd: 'components/bootstrap', (err, stdout, stderr) ->
                cb err, stderr
        (_, cb) ->
            util.log 'Building bootstrap'
            exec 'make bootstrap', cwd: 'components/bootstrap', (err, stdout, stderr) ->
                cb err, stderr
    ], (err, result) ->
        if err?
            util.log err
            if result?
                util.log result
