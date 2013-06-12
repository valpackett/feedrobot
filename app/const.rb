# the host, eg. 'appdotnetfeedrobot.herokuapp.com'
HOST = ENV['HOST']

# rack session secret... not very important
# only the admin uses sessions, can't harm users
SESSION_SECRET = ENV['SECRET_KEY'] || 'aaaaa'

# URL for getting a token. this is 'security by obscurity', but
# whatever. nothing bad could happen if a user gets there. it'd be like dev-lite
TOKEN_URL = ENV['TOKEN_URL'] || '/token'

# Redis
REDIS_URL = ENV['REDISTOGO_URL'] || ENV['REDIS_URL']

# ADN credentials
ADN_ID = ENV['ADN_ID']
ADN_SECRET = ENV['ADN_SECRET']

# first run without the token, visit the TOKEN_URL, paste the token to the variable
ADN_TOKEN = ENV['ADN_TOKEN']

# admin's ADN user ID, for streaming failure notifications
ADMIN_ADN_UID = ENV['ADMIN_ADN_UID']

# Superfeedr credentials
SUPERFEEDR_LOGIN = ENV['SUPERFEEDR_LOGIN']
SUPERFEEDR_PASSWORD = ENV['SUPERFEEDR_PASSWORD']
