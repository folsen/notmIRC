addUser = (user) ->
  el = document.createElement 'li'
  el.innerHTML = user.name
  document.getElementById('users').appendChild(el)

removeUser = (user) ->
  list = document.getElementById('users')
  for child in list.children
    if child.innerHTML is user.name
      list.removeChild(child)

message = (obj) ->
  el = document.createElement 'p'
  if 'announcement' of obj
    el.innerHTML = "<em class=\"#{esc(obj.color)}\">* #{esc(obj.announcement)} </em>"
  else if 'addUser' of obj
    addUser obj.addUser
  else if 'removeUser' of obj
    removeUser obj.removeUser
  else if 'updateCookie' of obj
    createCookie 'nick', obj.updateCookie
  else if 'message' of obj
    el.innerHTML = "[#{esc(obj.message[0])}] &lt;#{esc(obj.message[1])}&gt; #{esc(obj.message[2])}"
  document.getElementById('chat').appendChild(el)
  document.getElementById('chat').scrollTop = 1000000

this.send = ->
  val = document.getElementById('text').value
  socket.send val
  document.getElementById('text').value = ''

esc = (msg) ->
  msg.replace(/</g, '&lt;').replace(/>/g, '&gt;')

createCookie = (name,value) ->
  date = new Date()
  date.setTime(date.getTime()+(365*24*60*60*1000))
  expires = "; expires="+date.toGMTString()
  document.cookie = name+"="+value+expires+"; path=/"

this.socket = new io.Socket null, {port: 8080, rememberTransport: false}
socket.connect()
socket.on 'message', (obj) ->
  if 'buffer' of obj
    document.getElementById('form').style.display='block'
    document.getElementById('chat').innerHTML = ''
    for msg in obj.buffer 
      console.log msg
      message(msg)
  else if 'users' of obj
    for user in obj.users
      addUser user
  else message(obj)
  
initialize()

displayHelpBox = ->
  document.getElementById('helpbox').style.left = ((window.innerWidth - 500) / 2) + "px"
  document.getElementById('helpbox').style.top = ((window.innerHeight - 400) / 2) + "px"
  document.getElementById('helpbox').style.display = "block"
  
hideHelpBox = ->
  document.getElementById('helpbox').style.display = "none"
  
onLoad = ->
  document.getElementById('helplink').onclick = -> 
    displayHelpBox() 
    return false
  document.getElementById('closehelp').onclick = -> 
    hideHelpBox()
    return false

try
  window.addEventListener 'load', onLoad, false
catch e
  window.onload = onLoad