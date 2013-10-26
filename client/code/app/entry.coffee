# This file automatically gets called first by SocketStream and must always exist

# Make 'ss' available to all modules and the browser console
window.ss = require('socketstream')

ss.server.on 'disconnect', ->
  html = ss.tmpl['transmission_alert_not_ok'].render(guid:'', stdout:'Se ha perdido la conexión con el servidor')
  #$(html).hide().prependTo('#list').show()
  console.log('Connection down :-(')

ss.server.on 'reconnect', ->
  html = ss.tmpl['transmission_alert_not_ok'].render(guid:'', stdout:'Se ha restablecido la conexión con el servidor')
  $(html).hide().prependTo('#list').show()
  console.log('Connection back up :-)')

ss.server.on 'ready', ->

  # Wait for the DOM to finish loading
  jQuery ->
    
    # Load app
    require('/app')
