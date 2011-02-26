http = require 'http'
url = require 'url'
fs = require 'fs'
io = require 'socket.io'
sys = require 'sys'
express = require 'express'
app = express.createServer()

# Basic express configuration and route handling
app.configure ->
  app.use express.staticProvider(__dirname + '/public')
  app.set 'view options', { layout: false }

app.get '/',(req,res) ->
  res.render 'index.jade'

# Debug route to see that 500 errors work
app.get '/poop', (req,res) ->
  poop()

# Catch everything else and return 404
app.get '*', (req,res) ->
  res.render '404.jade', status: 404

# Render 500 in case of failure (only catches failures in the routes above, not in the socket.io code)
app.error (err, req, res) ->
  res.render '500.jade',
    status: 500,
    locals:
      error: err

app.listen 8080

# socket.io implementation of chat functionality

io = io.listen app
buffer = []
users = []

clientToUser = (client) ->
  name: client.sessionId

removeUser = (user) ->
  i = 0
  for usr in users
    if usr is user
      users.splice i,1
  i++

io.on 'connection', (client) ->
  user = clientToUser client
  users.push user
  client.send buffer: buffer
  client.send users: users
  client.broadcast addUser: user
  client.broadcast announcement: "#{user.name} connected"

  client.on 'message', (message) ->
    if message.substr(0,1) is '/'
      parseCommand message
    else
      parseMessage message

  client.on 'disconnect', ->
    client.broadcast announcement: "#{user.name} disconnected"
    removeUser user
    client.broadcast removeUser: user
    
  parseCommand = (message) ->
    split = message.split(/\s/)
    command = split[0].substr(1,split[0].length)
    args = split[1..split.length]
    switch command
      when "nick" then changeNick.apply this, args
      else client.send announcement: "There is no such command."
  
  parseMessage = (message) ->
    msg = message: [(new Date).toLocaleTimeString(), user.name, message]
    buffer.push msg
    buffer.shift if buffer.length > 15 
    client.send msg
    client.broadcast msg
  
  # Commands
  changeNick = (nick) ->
    client.send announcement: "You changed your nick to #{nick}."
    client.broadcast announcement: "User #{user.name} has changed his nick to #{nick}"
    io.broadcast removeUser: user
    user.name = nick
    io.broadcast addUser: user
    