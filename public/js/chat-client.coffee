message = (obj) ->
  el = document.createElement 'p'
  if 'announcement' of obj
    el.innerHTML = "<em> #{esc(obj.announcement)} </em>"
  else if 'message' of obj
    el.innerHTML = "<b> #{esc(obj.message[0])} :</b> #{esc(obj.message[1])}"
  document.getElementById('chat').appendChild(el)
  document.getElementById('chat').scrollTop = 1000000

this.send = ->
  val = document.getElementById('text').value
  socket.send val
  message message: ['you', val]
  document.getElementById('text').value = ''

esc = (msg) ->
  msg.replace(/</g, '&lt;').replace(/>/g, '&gt;')

socket = new io.Socket null, {port: 8080, rememberTransport: false}
socket.connect()
socket.on 'message', (obj) ->
  if 'buffer' of obj
    document.getElementById('form').style.display='block'
    document.getElementById('chat').innerHTML = ''
    for msg in obj.buffer 
      message(msg)
  else message(obj)