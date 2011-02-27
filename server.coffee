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

app.get '/:channel/:secret?', (req,res) ->
  res.render 'chat.ejs',
    locals:
      channel: req.params.channel
      secret: req.params.secret

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
clients = []
  
readCookie = (cookie) ->
  ca = cookie.split(';')
  r = {}
  for cn in ca
    r[cn.split('=')[0].trim()] = cn.split('=')[1]
  return r

publish = (channel, msg) ->
  for client in clients
    if client.channel is channel
      client.send(msg)

io.on 'connection', (client) ->
  client.name = "user_#{client.sessionId}"
  clients.push client
  client.send buffer: buffer
  cookiestore = {}
  
  client.on 'message', (message) ->
    if typeof message isnt "string" and 'cookie' of message
      cookiestore = readCookie message.cookie
      if 'nick' of cookiestore
        client.name = cookiestore.nick
        client.channel = message.channel
      addUser client
      sys.log sys.inspect clients.map (c)-> {id: c.sessionId, name: c.name, channel: c.channel}
    else if message.substr(0,1) is '/'
      parseCommand message
    else
      parseMessage message

  client.on 'disconnect', ->
    client.broadcast {announcement: "#{client.name} disconnected", color: "blue"}
    removeClient client
    client.broadcast removeUser: {name: client.name}
  
  addUser = (client) ->
    client.send users: clients.map (c)-> {name: c.name}
    client.broadcast addUser: {name: client.name}
    client.broadcast {announcement: "#{client.name} connected", color: "green"}
    
  removeClient = (client) ->
    i = 0
    for c in clients
      if c.sessionId is client.sessionId
        return clients.splice i,1
      i++
  
  parseCommand = (message) ->
    split = message.split(/\s/)
    command = split[0].substr(1,split[0].length)
    args = split[1..split.length]
    switch command
      when "nick" then changeNick.apply this, args
      when "me" then me.apply this, args
      else client.send {announcement: "There is no such command.", color: "blue"}
  
  parseMessage = (message) ->
    msg = message: [(new Date).toLocaleTimeString(), client.name, message]
    buffer.push msg
    buffer.shift if buffer.length > 15 
    client.send msg
    client.broadcast msg
  
  # Commands
  changeNick = (nick) ->
    client.send {announcement: "You changed your nick to #{nick}.", color: "green"}
    client.send updateCookie: nick
    client.broadcast {announcement: "User #{client.name} has changed his nick to #{nick}", color: "green"}
    io.broadcast removeUser: {name: client.name}
    client.name = nick
    io.broadcast addUser: {name: client.name}
    
  me = ->
    string = ""
    for s in arguments
      string += " #{s}"
    io.broadcast {announcement: "#{client.name} #{string}", color: "purple"}
    