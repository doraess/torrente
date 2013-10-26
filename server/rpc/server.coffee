request = require('request')
fs = require("fs")
url = require("url")
exec = require("child_process").exec
spawn = require("child_process").spawn
path = require 'path'
dive = require 'dive'

DOWNLOAD_DIR = "/home/alberto/torrents/"
MOVIES_DIR = "/media/WD-2TB/Cloud/Peliculas/"
USER = "alberto"
PASSWORD = "Albmartin2012"
KEY = "c9cc121a2f584feba78d10bdab4d6033"

String::format = ->
  args = arguments
  @replace /{(\d+)}/g, (match, number) ->
    (if typeof args[number] isnt "undefined" then args[number] else match)
    
exports.actions = (req, res, ss) ->
  req.use('session')
  thePirateBay: (query) ->
    console.log query
    options =
      uri: "http://apify.ifc0nfig.com/tpb/search?id=#{query}&key=#{KEY}".format(query)
      #uri: "http://isohunt.com/js/json.php?ihq={0}&start=0&rows=20&sort=seed".format(query)
      followAllRedirects: "true"
      followRedirect: "true"
      method: "GET"
    request.get options, (error, response, body) ->
      if not error
        ss.publish.all "torrent-thepiratebay", response
        console.log response
      else
        console.log error
  isoHunt: (query) ->
    options =
      uri: "http://isohunt.com/js/json.php?ihq={0}&start=0&rows=20&sort=seed".format(query)
      followAllRedirects: "true"
      followRedirect: "true"
      method: "POST"
    request.post options, (error, response, body) ->
      if not error
        ss.publish.all "torrent-thepiratebay", response
      else
        console.log error
  download_file_curl: (guid) ->
    file_url = "http://ca.isohunt.com/download/" + guid
    file = fs.createWriteStream(DOWNLOAD_DIR + guid + ".torrent")
    curl = spawn("curl", [file_url])
    curl.stdout.on "data", (data) ->
      file.write data
    curl.stdout.on "end", (data) ->
      file.end()
      console.log guid + " downloaded to " + DOWNLOAD_DIR
      add = "transmission-remote localhost:3071 -n alberto:Albmartin2012 -a /home/alberto/torrents/{0}.torrent".format guid
      console.log add
      child = exec add, (err, stdout, stderr) -> 
        if not err
          ss.publish.all "transmission_alert_ok", guid, stdout
        else
          ss.publish.all "transmission_alert_not_ok", guid, stderr
    curl.on "exit", (code) ->
      console.log "Failed: " + code unless code is 0
      
  download_file_wget: (guid) ->
    file_url = "http://ca.isohunt.com/download/" + guid
    wget = "wget -P " + DOWNLOAD_DIR + " - O " + guid + ".torrent " + file_url
    child = exec wget, (err, stdout, stderr) ->
      if err
        throw err
      else
        console.log file_name + " downloaded to " + DOWNLOAD_DIR
  getTransmissionStatus: ->
    transmission = "transmission-remote localhost:3071 -n alberto:Albmartin2012 -l"
    child = exec transmission, (err, stdout, stderr) ->
      if err
        throw err
      else
        console.log stdout
        ss.publish.all "transmission", stdout
  stopDownload: (id) ->
    transmission = "transmission-remote localhost:3071 -n alberto:Albmartin2012 -t#{id} -S"
    child = exec transmission, (err, stdout, stderr) ->
      if err
        throw err
      else
        console.log stdout
  
  startDownload: (id) ->
    transmission = "transmission-remote localhost:3071 -n alberto:Albmartin2012 -t#{id} -s"
    child = exec transmission, (err, stdout, stderr) ->
      if err
        throw err
      else
        console.log stdout
        
  addMagnet: (magnet, name) ->
    console.log magnet
    add = "transmission-remote localhost:3071 -n alberto:Albmartin2012 -a \"#{magnet}\" -s"
    console.log add
    child = exec add, (err, stdout, stderr) -> 
      if not err
        ss.publish.all "transmission_alert_ok", name, stdout
      else
        console.log err
        console.log stderr
        ss.publish.all "transmission_alert_not_ok", name, stderr
      
  removeDownload: (id, type) ->
    if type is "f"
      transmission = "transmission-remote localhost:3071 -n alberto:Albmartin2012 -t#{id} --remove-and-delete"
    else
      transmission = "transmission-remote localhost:3071 -n alberto:Albmartin2012 -t#{id} -r"
    child = exec transmission, (err, stdout, stderr) ->
      if err
        throw err
      else
        console.log stdout
      
  removeFile: (file) ->
    rm = "rm #{MOVIES_DIR}#{file.replace(/%20/g, '\\ ')}"
    console.log rm
    child = exec rm, (err, stdout, stderr) ->
      console.log stdout, stderr
      ls = "ls -allh --group-directories-first /media/WD-2TB/Cloud/Peliculas"
      child = exec ls, (err, stdout, stderr) ->
        if err
          throw err
        else
          ss.publish.all 'library', stdout 
      
#  getVideoLibrary: ->
#    files = []
#    walker = walk.walk '/media/WD-2TB/Cloud/Peliculas', 
#      followLinks: false
#    walker.on "file", (root, stat, next) ->
#      stat.root = root
#      files.push stat
#      next()
#    walker.on 'end', () ->
#      ss.publish.all 'library', files
    #ls = "ls -allh --group-directories-first /media/WD-2TB/Cloud/Peliculas"
    #child = exec ls, (err, stdout, stderr) ->
    #  if err
    #    throw err
    #  else 
    #    ss.publish.all 'library', stdout
    
  getVideoLibrary: ->
    files = []
    dive '/media/WD-2TB/Cloud/Peliculas',
      all: false
    , ((err, file) ->
      if err
        console.log err
      else
        stats = fs.statSync(file)
        file_ext =
          name : path.basename file
          extension : path.extname(file).substr(path.extname(file)-2)
          size : stats.size
        files.push file_ext
    ), ->
      ss.publish.all 'library', files
      
  downloadFile: (file) ->
    console.log req
    files.serve(file, req, res)
