http = require 'http'
url = require 'url'
fs = require 'fs'
io = require 'socket.io'
sys = require 'sys'
express = require 'express'
app = express.createServer()
    
app.configure ->
  app.use express.staticProvider(__dirname + '/public')
  app.set 'view options', { layout: false } 

app.get '/',(req,res) ->
  res.render 'index.jade'

app.get '/poop', (req,res) ->
  poop()

app.get '*', (req,res) ->
  res.render '404.jade', status: 404

app.error (err, req, res) ->
  res.render '500.jade',
    status: 500,
    locals:
      error: err

app.listen 8080

# socket.io, I choose you
# simplest chat application evar
io = io.listen app
buffer = []

io.on 'connection', (client) ->
  client.send buffer: buffer
  client.broadcast announcement: "#{client.sessionId} connected"

  client.on 'message', (message) ->
    msg = message: [client.sessionId, message]
    buffer.push msg
    buffer.shift if buffer.length > 15 
    client.broadcast msg 

  client.on 'disconnect', ->
    client.broadcast announcement: client.sessionId + ' disconnected'
