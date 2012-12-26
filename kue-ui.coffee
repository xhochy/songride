kue = require('kue')

# Create job queue
jobs = kue.createQueue()
kue.app.listen(3001, '127.0.0.1')

