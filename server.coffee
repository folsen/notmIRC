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
  
readCookie = (cookie) ->
  ca = cookie.split(';')
  r = {}
  for cn in ca
    r[cn.split('=')[0].trim()] = cn.split('=')[1]
  return r
      
io.on 'connection', (client) ->
  user = { id: client.sessionId, name: "Bob" }
  users.push user
  client.send buffer: buffer
  cookiestore = {}

  client.on 'message', (message) ->
    if typeof message isnt "string" and 'cookie' of message
      cookiestore = readCookie message.cookie
      sys.log sys.inspect cookiestore
      if 'nick' of cookiestore
        user.name = cookiestore.nick
      addUser user
      sys.log sys.inspect users
    else if message.substr(0,1) is '/'
      parseCommand message
    else
      parseMessage message

  client.on 'disconnect', ->
    client.broadcast {announcement: "#{user.name} disconnected", color: "blue"}
    removeUser user
    client.broadcast removeUser: user
  
  addUser = (user) ->
    client.send users: users
    client.broadcast addUser: user
    client.broadcast {announcement: "#{user.name} connected", color: "green"}
    
  removeUser = (user) ->
    i = 0
    for usr in users
      if usr.id is user.id
        return users.splice i,1
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
    msg = message: [(new Date).toLocaleTimeString(), user.name, message]
    buffer.push msg
    buffer.shift if buffer.length > 15 
    client.send msg
    client.broadcast msg
  
  # Commands
  changeNick = (nick) ->
    client.send {announcement: "You changed your nick to #{nick}.", color: "green"}
    client.send updateCookie: nick
    client.broadcast {announcement: "User #{user.name} has changed his nick to #{nick}", color: "green"}
    io.broadcast removeUser: user
    user.name = nick
    io.broadcast addUser: user
    
  me = ->
    string = ""
    for s in arguments
      string += " #{s}"
    io.broadcast {announcement: "#{user.name} #{string}", color: "purple"}
    