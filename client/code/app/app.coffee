# Client Code

console.log('App Loaded')

torrents = ''

updateSidebar = ->  
  html = ss.tmpl['sidebar'].render()
  $('#sidebar').html('')
  $(html).hide().appendTo('#sidebar').slideDown()

updateNavigation = ->    
  html = ss.tmpl['navigation'].render()
  $('#navigation').html('')
  $(html).hide().appendTo('#navigation').show()
    
ss.event.on 'torrent-thepiratebay', (data) ->
  torrents = JSON.parse(data.body)
  for torrent in torrents
    console.log torrent
    html = ss.tmpl['torrent'].render(torrent: torrent)
    $(html).hide().appendTo('#list').slideDown()

ss.event.on 'transmission_alert_ok', (guid, stdout) ->
  html = ss.tmpl['transmission_alert_ok'].render(guid:guid, stdout:stdout)
  $(html).hide().prependTo('#list').show()
  
ss.event.on 'transmission_alert_not_ok', (guid, stdout) ->
  html = ss.tmpl['transmission_alert_not_ok'].render(guid:guid, stdout:stdout)
  $(html).hide().prependTo('#list').show()
    
ss.event.on 'transmission', (status) ->
  $('#transmission_status').html('')
  status = status.split('\n')
  pattern = "([0-9]{1,3}) *([0-9]{1,3})% *([0-9.]* [a-zA-Z]{2,4}) *([0-9]*[ ]?[a-zA-Z]*) *([0-9.]*) *([0-9.]*) *([0-9.None]*) *([a-zA-Z &]{0,11}) *(.*)$"
  end = status.length - 2
  for torrent in status[1..end]
    if torrent.match(pattern)
      if torrent.match(pattern)[9].length > 70
        torrent_name = torrent.match(pattern)[9][0..70] + '...'
      else
        torrent_name = torrent.match(pattern)[9].trim()
      red = parseInt 255*(1- torrent.match(pattern)[2].trim()/100)
      green = parseInt 255*torrent.match(pattern)[2].trim()/100
      download =
        id : torrent.match(pattern)[1].trim()
        done : torrent.match(pattern)[2].trim()
        have : torrent.match(pattern)[3].trim()
        eta : torrent.match(pattern)[4].trim()
        up : torrent.match(pattern)[5].trim()
        down : torrent.match(pattern)[6].trim()
        ratio : torrent.match(pattern)[7].trim()
        status : torrent.match(pattern)[8].trim()
        name : torrent_name
        color: 'rgb(' + red + ',' + green + ',' + 0 + ')'
      html = ss.tmpl['download'].render(download: download)
      $(html).appendTo('#transmission_status').show()
      for span in $('span')
        if $(span).html() in ['Up &amp; Down', 'Downloading'] 
          $(span).addClass("ink-label success invert")
        if $(span).html() in ['Stopped', 'Unknown', 'None'] 
          $(span).addClass("ink-label caution invert")
        if $(span).html() in ['Seeding', 'Idle', 'Done'] 
          $(span).addClass("ink-label info invert")


ss.event.on 'library', (files) ->
  console.log files
  $('#video_list').html('')
  files = files.sort (a, b) ->
    return if a.name.toUpperCase() >= b.name.toUpperCase() then 1 else -1
  for file in files
    file.size = sizeConvert file.size
    extension = file.extension.substr(1)
    if extension in ['avi', 'mpg', 'mkv', 'srt', 'txt']
      if file.name.length > 55 then file.name = file.name[0..55] + '...'
      html = ss.tmpl['movie'].render(file: file)
      $(html).appendTo('#video_list').show()
      $(".type").last().html("<i class='icon-film icon-large'></i> ")
      if extension is 'srt'
        $(".type").last().html("<i class='icon-file icon-large'></i> ")
      $(".type").last().addClass(extension)

app = Davis(->
  @get "/search", (req) ->
    $('#content').html('')
    html = ss.tmpl['console'].render()
    $(html).hide().appendTo('#content').show()
  
  @get "/stop/:id", (req) ->
    ss.rpc "server.stopDownload", req.params['id']
  
  @get "/start/:id", (req) ->
    ss.rpc "server.startDownload", req.params['id']
  
  @get "/remove_files/:id", (req) ->
    ss.rpc "server.removeDownload", req.params['id'], 'f'
  
  @get "/remove/:id", (req) ->
    ss.rpc "server.removeDownload", req.params['id']
  
  @get "/remove_movie/:name", (req) ->
    ss.rpc "server.removeFile", req.params['name']
  
  @get "/download_movie/:name", (req) ->
    ss.rpc "server.downloadFile", req.params['name']
  
  @get "/play_movie/:name", (req) ->
    $('#content').html('')
    html = ss.tmpl['video_player'].render(movie: req.params['name'])
    $(html).hide().appendTo('#content').show()
  
  @get "/downloads", (req) ->
    $('#content').html('')
    html = ss.tmpl['transmission'].render()
    $(html).hide().appendTo('#content').show()
    ss.rpc "server.getTransmissionStatus"
  
  @get "/video", (req) ->
    $('#content').html('')
    html = ss.tmpl['video_library'].render()
    $(html).hide().appendTo('#content').show()
    ss.rpc "server.getVideoLibrary"
  
  @post "/search/torrents", (req) ->
    $('#list').html('')
    ss.rpc "server.thePirateBay", req.params['query']
  
  @get "/download/:name/:id", (req)->
    #console.log req.params['magnet']
    magnet = ''
    console.log req.params.id
    for torrent in torrents
      console.log torrent.id
      if torrent.id.toString() is req.params.id
        magnet = torrent.magnet
    console.log magnet
    ss.rpc "server.addMagnet", magnet, req.params.name
)
app.start()

updateNavigation()
updateSidebar()

html = ss.tmpl['console'].render()
$(html).hide().appendTo('#content').show()