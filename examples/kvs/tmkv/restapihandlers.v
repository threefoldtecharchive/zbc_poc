module tmkv

import json
import net.http

struct ApiResponse {
	code int
	status string
	log string
	result map[string]string
}

pub interface RestApiHandler {
mut:
	app &KVApp

	handle(string) http.Response
}

pub struct GetHandler {
mut:
	app &KVApp
}


pub fn (mut h GetHandler) handle(data string) http.Response {
	if data == "" {
		return create_response(1, "Invalid input! The key cannot be empty.", map[string]string{})
	}

	value := h.app.get_value(data) or {
		return create_response(1, "The key ${data} does not exist.", map[string]string{})
	}
	
	mut result := map[string]string {}
	result[data] = value
	return create_response(0, "", result)
}


pub struct SetHandler {
mut: 
	app &KVApp
}

pub fn (mut h SetHandler) handle(data string) http.Response {
	key_val := data.split_nth("=", 2)

	if key_val.len != 2 || key_val[1] == "" {
		return create_response(1, "Invalid input! The key and/or the value cannot be empty.", map[string]string{})
	}

	h.app.set_value(key_val[0], key_val[1]) or {
		return create_response(1, "$err", map[string]string{})
	}

	mut result := map[string]string {}
	result[key_val[0]] = key_val[1]
	return create_response(0, "", result)
}

fn create_response(code int, log string, result map[string]string) http.Response {
	return http.new_response(http.ResponseConfig {
		header: http.new_header(http.HeaderConfig{})
		body: json.encode(ApiResponse{
			code: code
			status: match code {
				0 { "SUCCESS" }
				else { "FAILURE" }
			}
			log: log
			result: result
		})
	})
}