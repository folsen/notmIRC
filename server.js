var http = require('http')
  , url = require('url')
  , fs = require('fs')
  , io = require('socket.io')
  , sys = require(process.binding('natives').util ? 'util' : 'sys')
  , express = require('express')
  , app = express.createServer();
    
app.configure(function(){
  app.use(express.staticProvider(__dirname + '/public'));
  app.set('view options', {
      layout: false
  });
});

app.get('/',function(req,res){
  res.render('index.jade');
});

app.get('/poop',function(req,res){
  poop();
});

app.get('*', function(req,res){
  res.render('404.jade', { status: 404 });
});

app.error(function(err, req, res) {
  res.render('500.jade', {
    status: 500,
    locals: {
      error: err
    } 
  });
});

app.listen(8080);

// socket.io, I choose you
// simplest chat application evar
var io = io.listen(app)
  , buffer = [];
  
io.on('connection', function(client){
  client.send({ buffer: buffer });
  client.broadcast({ announcement: client.sessionId + ' connected' });
  
  client.on('message', function(message){
    var msg = { message: [client.sessionId, message] };
    buffer.push(msg);
    if (buffer.length > 15) buffer.shift();
    client.broadcast(msg);
  });

  client.on('disconnect', function(){
    client.broadcast({ announcement: client.sessionId + ' disconnected' });
  });
});
