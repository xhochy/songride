kue = require('kue')

# Create job queue
jobs = kue.createQueue()
# This UI should only be viewable via localhost as there is no authentication
# included.
kue.app.listen(3001, '127.0.0.1')

