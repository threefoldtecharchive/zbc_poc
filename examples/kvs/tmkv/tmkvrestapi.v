module tmkv

import log
import net.http


pub fn new_tmkvrestapi(port int, handlers map[string]&RestApiHandler, logger &log.Logger) &http.Server {
	return &http.Server {
		port: port
		handler: TmKVRestApiHandler {
			logger: unsafe { logger }
			handlers: handlers
		}
	}
}

pub struct TmKVRestApiHandler {
mut:
	handlers map[string]&RestApiHandler
	logger &log.Logger
}

pub fn (mut h TmKVRestApiHandler) handle(req http.Request) http.Response {
	url := req.url
	url_lowered := url.to_lower()
	if url_lowered.starts_with("/") {
		data := url_lowered[1..].split_nth("?", 2)
		if data.len == 2 && data[0] in h.handlers {
			return h.handlers[data[0]].handle(data[1])
		}
	}

	return http.new_response(http.ResponseConfig {
		header: http.new_header(http.HeaderConfig{})
		body: "Unknown handler"
	})
}