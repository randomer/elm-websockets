'use strict'

;(function() {

var initSignals = {
	statuses: {
		tag: '',
		status: -1,
		protocol: '',
		error: ''
	},
	data: {
		tag: '',
		data: ''
	}
}

var ClientWSapp = Elm.fullscreen(Elm.Main, initSignals)
// var ClientWSapp = Elm.worker(Elm.WebSockets.Client, initSignals)

var openSockets = []

ClientWSapp.ports.doOpen.subscribe(function(config) {
	console.log(config)
	if (config.port_ < 0) {
		return // Fail silently
	}

	var ws = new WebSocket('ws://' + config.host + ':' + config.port_, config.protocols)
	ws.addEventListener('open', function(openEvent) {
		openSockets.push({tag: config.tag, ws: ws})

		var socket = openEvent.target
		
		ClientWSapp.ports.statuses.send({
			tag: config.tag,
			status: socket.readyState,
			protocol: socket.protocol,
			error: null
		})
		console.log(openEvent)
	})
	ws.addEventListener('message', function(msgEvent) {
		var socket = msgEvent.target

		console.log('Message received: "' + msgEvent.data + '"')
		ClientWSapp.ports.data.send({
			tag: config.tag,
			data: msgEvent.data
		})
	})
	ws.addEventListener('error', function(errorEvent, a, b) {
		console.log(errorEvent)
		console.log(a)
		console.log(b)
		ClientWSapp.ports.statuses.send({
			tag: config.tag,
			status: errorEvent.target.readyState,
			protocol: errorEvent.target.protocol,
			// error: errorEvent.message
			error: null
		})
		console.log(errorEvent)
	})
	ws.addEventListener('close', function(closeEvent) {
		var socket = closeEvent.target

		ClientWSapp.ports.statuses.send({
			tag: config.tag,
			status: socket.readyState,
			protocol: socket.protocol,
			error: null
		})

		console.log(closeEvent)

		// var socketIndex = openSockets.indexOf(socket)
		// if (socketIndex >= 0) {
		// 	openSockets.splice(socketIndex, 1)
		// }
	})

	ClientWSapp.ports.doSend.subscribe(function(taggedData) {
		for (var i = 0; i < openSockets.length; i++) {
			var taggedSocket = openSockets[i]
			if (config.tag === taggedSocket.tag) {
				console.log('Sending: "' + taggedData.data + '"')
				taggedSocket.ws.send(taggedData.data)
			}
		}
	})

	ClientWSapp.ports.doClose.subscribe(function(tag) {
		for (var i = 0; i < openSockets.length; i++) {
			var taggedSocket = openSockets[i]
			if (config.tag === taggedSocket.tag) {
				taggedSocket.ws.close()
			}
		}
	})
})

})()