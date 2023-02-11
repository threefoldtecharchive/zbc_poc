module tmkv

import json
import log
import net.websocket


pub struct TmWsMessage {
pub: 
	handler string
	request string
}

pub struct TmWsResponse {
pub:
	error string
	response string
}

[heap]
pub struct TmWsServer {
	port int

pub mut:
	server &websocket.Server
	handlers map[string]&WsHandler
	logger &log.Logger = unsafe { nil }
}

pub fn new_tmwsserver(port int, handlers map[string]&WsHandler, logger &log.Logger) !&TmWsServer {
	mut server := websocket.new_server(.ip, port, "", websocket.ServerOpt {
			logger: unsafe { logger }
	})
	tm_server := TmWsServer {
		port: port
		server: server
		handlers: handlers
		logger: unsafe { logger }
	}

	server.on_connect(tm_server.on_connect)!
	server.on_message(tm_server.on_message)
	server.on_close(tm_server.on_close)

	return &tm_server
}

fn (mut tc TmWsServer) write_error(mut client websocket.Client, message string) ! {
	tc.logger.error(message)
	tmwsresponse := TmWsResponse {
		error: message,
		response: ""
	}
	client.write_string(json.encode(tmwsresponse))!
}

fn (mut tc TmWsServer) on_message(mut client websocket.Client, msg &websocket.Message) ! {
	if msg.opcode != .text_frame && msg.opcode != .binary_frame{
		tc.logger.warn("Not a text message: ${msg.opcode}")
		return
	}

	tmwsmessage := json.decode(TmWsMessage, msg.payload.bytestr()) or {
		tc.write_error(mut client, "Failed decoding message: $err")!
		return 
	}
	// todo call handler and send reply
	if !(tmwsmessage.handler in tc.handlers) {
		tc.logger.warn("No available handler for method ${tmwsmessage.handler}")
		return
	}
	tc.logger.info("Handeling a message of type ${tmwsmessage.handler}")
	tc.logger.debug("Message: ${tmwsmessage}")

	response := tc.handlers[tmwsmessage.handler].handle(tmwsmessage.request) or {
		tc.write_error(mut client, "Failed handeling request: $err")!
		return 
	}

	tmwsresponse := TmWsResponse {
		error: "",
		response: response
	}
	tc.logger.debug("Response: ${tmwsresponse}")
	client.write_string(json.encode(tmwsresponse))!
}

fn (mut tc TmWsServer) on_close(mut client websocket.Client, code int, reason string) ! {
	tc.logger.info("Closing connection to client")
}

fn (mut tc TmWsServer) on_connect(mut client websocket.ServerClient) !bool {
	tc.logger.info("New client connection")
	return true
}

pub fn (mut tc TmWsServer) run() ! {
	tc.logger.info("Lets start listening!")
	tc.server.listen()!
}
