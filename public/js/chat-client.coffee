addUser = (user) ->
  el = document.createElement 'li'
  el.innerHTML = user.name
  document.getElementById('users').appendChild(el)

removeUser = (user) ->
  list = document.getElementById('users')
  for child in list.children
    if child.innerHTML == user.name
      list.removeChild(child)

message = (obj) ->
  el = document.createElement 'p'
  if 'announcement' of obj
    el.innerHTML = "<em> #{esc(obj.announcement)} </em>"
  else if 'addUser' of obj
    addUser obj.addUser
  else if 'removeUser' of obj
    removeUser obj.removeUser
  else if 'message' of obj
    el.innerHTML = "#{esc(obj.message[0])} - <b> #{esc(obj.message[1])} :</b> #{esc(obj.message[2])}"
  document.getElementById('chat').appendChild(el)
  document.getElementById('chat').scrollTop = 1000000

this.send = ->
  val = document.getElementById('text').value
  socket.send val
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
  else if 'users' of obj
    for user in obj.users
      addUser user
  else message(obj)