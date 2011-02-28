http = require 'http'
url = require 'url'
fs = require 'fs'
io = require 'socket.io'
sys = require 'sys'
express = require 'express'
app = express.createServer()
mongoose = require('mongoose')
db = mongoose.connect('mongodb://localhost/notmirc')

Schema = mongoose.Schema
ObjectId = Schema.ObjectId

MessageSchema = new Schema
  id: ObjectId,
  channel: String,
  time: String,
  nick: String,
  msg: {type: String}
    
mongoose.model('Message', MessageSchema)

Message = mongoose.model('Message')

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
clients = []
  
readCookie = (cookie) ->
  ca = cookie.split(';')
  r = {}
  for cn in ca
    r[cn.split('=')[0].trim()] = cn.split('=')[1]
  return r

publish = (from, channel, msg) ->
  if not ('addUser' of msg or 'removeUser' of msg)
    m = new Message
      channel: channel, 
      time: new Date, 
      nick: from.name, 
      msg: JSON.stringify(msg)
    m.save()
  for client in clients
    if client.channel is channel
      client.send(msg)
      
broadcast = (from, channel, msg) ->
  if not ('addUser' of msg or 'removeUser' of msg)
    m = new Message
      channel: channel, 
      time: new Date, 
      nick: from.name, 
      msg: JSON.stringify(msg)
    m.save()
  for client in clients
    if client.channel is channel and client.sessionId isnt from.sessionId
      client.send(msg)

usersOfChannel = (channel) ->
  _res = []
  for client in clients
    if client.channel is channel
      _res.push client
  return _res.map (c)-> {name: c.name}

removeClient = (client) ->
  i = 0
  for c in clients
    if c.sessionId is client.sessionId
      return clients.splice i,1
    i++
    
sendBuffer = (client) ->
  Message.find {channel: client.channel}, ['msg'], (err, docs) ->
    buffer = docs.map (doc) -> JSON.parse doc.msg
    client.send buffer: buffer
    if buffer.length < 1
      client.send {announcement: "You created a new channel.", color: "green"}

io.on 'connection', (client) ->
  client.name = "user_#{client.sessionId}"
  clients.push client
  cookiestore = {}
  
  client.on 'message', (message) ->
    if typeof message isnt "string" and 'cookie' of message
      cookiestore = readCookie message.cookie
      if 'nick' of cookiestore
        client.name = cookiestore.nick
        client.channel = message.channel
      addUser client
      sendBuffer(client)
        
      sys.log sys.inspect clients.map (c)-> {id: c.sessionId, name: c.name, channel: c.channel}
      sys.log sys.inspect usersOfChannel client.channel
    else if message.substr(0,1) is '/'
      parseCommand message
    else
      parseMessage message

  client.on 'disconnect', ->
    publish client, client.channel, {announcement: "#{client.name} disconnected", color: "blue"}
    removeClient client
    publish client, client.channel, removeUser: {name: client.name}
  
  addUser = (client) ->
    client.send users: usersOfChannel client.channel
    broadcast client, client.channel, {addUser: {name: client.name}}
    publish client, client.channel, {announcement: "#{client.name} connected", color: "green"}
  
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
    publish client, client.channel, msg
  
  # Commands
  changeNick = (nick) ->
    client.send updateCookie: nick
    publish client, client.channel, {announcement: "#{client.name} changed nickname to #{nick}", color: "green"}
    publish client, client.channel, removeUser: {name: client.name}
    client.name = nick
    publish client, client.channel, addUser: {name: client.name}
    
  me = ->
    string = ""
    for s in arguments
      string += " #{s}"
    publish client, client.channel, {announcement: "#{client.name} #{string}", color: "purple"}
    