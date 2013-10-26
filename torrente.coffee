# My SocketStream 0.3 app
http = require("http")
ss = require("socketstream")
exec = require("child_process").exec

#vidstreamer = require("vid-streamer")

# Define a single-page client called 'main'
ss.client.define "main",
  view: "app.jade"
  css: ["app.styl"]
  code: ["libs/jquery.min.js", "libs/davis.min.js", "app"]
  tmpl: "*"


# Serve this client on the root URL
ss.http.route "/", (req, res) ->
  res.serveClient "main"


# Code Formatters
ss.client.formatters.add require("ss-coffee")
ss.client.formatters.add require("ss-jade")
ss.client.formatters.add require("ss-stylus")

# Use server-side compiled Hogan (Mustache) templates. Others engines available
ss.client.templateEngine.use require("ss-hogan")

# Minimize and pack assets if you type: SS_ENV=production node app.js
ss.client.packAssets() if ss.env is "production"

# Start web server
server = http.Server(ss.http.middleware)
server.listen 3001

#settings =
#  mode: "development"
#  forceDownload: false
#  random: false
#  rootFolder: "/media/WD-2TB/Cloud/Peliculas/"
#  rootPath: ""
#  server: "VidStreamer.js/0.1.4"
  
#app = http.createServer(vidstreamer.settings(settings));
#app.listen(3011);

# Start Console Server (REPL)
# To install client: sudo npm install -g ss-console
# To connect: ss-console <optional_host_or_port>
consoleServer = require("ss-console")(ss)
consoleServer.listen 5000

# Start SocketStream
ss.start server

get_transmission_update = ->
  transmission = "transmission-remote localhost:3071 -n alberto:Albmartin2012 -l"
  child = exec transmission, (err, stdout, stderr) ->
    if err
      throw err
    else
      ss.api.publish.all "transmission", stdout

setInterval ( ->
  get_transmission_update()
  ), 1000
