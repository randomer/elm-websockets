'use strict'


var initSignals = {
	requests: {
		id: 1,
		port_: -1,
		// origin: "",
		protocols: []
	},
	openConnections: [],
	data: {
		connection: {
			id: -1,
			port_: -1,
			origin: "",
			protocol: "",
		},
		data: "",
		openConnections: []
	}
}

var Elm = require('./main.elm.js')
var ports = Elm.worker(Elm.Main, initSignals).ports
var WebSocketServer = require('ws').Server

ports.newServer.subscribe(function(server) {
	var port = server.port_
	var requestCounter = 0
	var options = {
		port: port,
		handleProtocols: function(protocols, cb) {
			var id = requestCounter++
			var request = {
				id: id,
				port_: port,
				// origin: 
				protocols: protocols
			}
			console.log(request)
			for (var i = 0; i < server.protocols.length; i++) {
				var servProtocol = server.protocols[i]
				if (protocols.indexOf(servProtocol) >= 0) {
					console.log('Accepted handshake')
					cb(true, servProtocol)
					return
				}
			}
			console.log('Refused handshake')
			console.log(request)
			// ports.requests.send(request)
			// ports.reqResult.subscribe(function(reqResult) {
			// 	if (reqResult.req.id === id) {
			// 		console.log(reqResult)
			// 		var result
			// 		if (reqResult.protocol !== null) {
			// 			result = true
			// 		} else {
			// 			result = false
			// 		}
			// 		console.log(result)
			// 		cb({
			// 			result: true,
			// 			protocol: reqResult.protocol
			// 		})
			// 	}
			// })
		},
	}
	
	var wsServer = new WebSocketServer(options, function() {console.log('WebSocket server on port ' + port)})

	var connectionCounter = 0
	var connections = []

	wsServer.on('headers', function(headers) {
		console.log('Headers sent:')
		console.log(headers)
	})

	wsServer.on('error', function(a,b,c) {
		console.log('Error:')
		console.log(a,b,c)
	})

	// Called regardless of whether the handshake was successful or not
	wsServer.on('connection', function(socket) {
		var id = connectionCounter++
		console.log('Connected with protocol "' + socket.protocol + '"')
		// console.log(socket)
		var protocol = socket.protocol
		if (!protocol) {
			protocol = null
		}
		var connection = {
			id: id,
			port_: port,
			origin: socket.upgradeReq.headers.origin,
			protocol: protocol
		}
		connections.push(connection)
		ports.openConnections.send(connections)

		ports.outgoing.subscribe(function(conData) {
			console.log('Outgoing: "' + conData.data + '"')
			if (conData.connections.indexOf(connection.id) >= 0) {
				console.log('Sending: "' + conData.data + '"')
				socket.send(conData.data)
			}
		})

		socket.on('message', function(dataString) {
			console.log('New message: "' + dataString + '"')
			ports.data.send({
				data: dataString,
				connection: connection,
				openConnections: connections
			})
		})

		socket.on('close', function(a,b,c) {
			console.log('Closing:')
			console.log(a,b,c)
			var indexToRemove = connections.indexOf(connection)
			connections.splice(indexToRemove, 1)
			ports.openConnections.send(connections)
		})
	})
})