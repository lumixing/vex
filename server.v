import net.http
import json
import time
import log

struct AuthResponseData {
	access_token  string
	refresh_token string
	expires_in    int
}

struct ServerHandler {
	config Config
mut:
	session_chan &chan Session
}

fn (mut h ServerHandler) handle(req http.Request) http.Response {
	mut res := http.Response{
		header: http.new_header_from_map({
			.content_type: 'text/plain'
		})
	}

	if req.url.starts_with('/auth') {
		code := req.url.split('=')[1]

		url := url_encode('https://accounts.spotify.com/api/token', {
			'grant_type':   'authorization_code'
			'redirect_uri': h.config.redirect_uri()
			'code':         code
		})

		mut auth_req := http.new_request(.post, url, '')
		auth_req.add_header(.authorization, 'Basic ${h.config.auth_hash()}')
		auth_req.add_header(.content_type, 'application/x-www-form-urlencoded')
		auth_req.add_header(.content_length, '0')

		auth_res := auth_req.do() or { panic('Could not request access token at ${url}: ${err}') }
		auth_res_data := json.decode(AuthResponseData, auth_res.body) or {
			panic('Could not parse auth response body: ${auth_res}')
		}
		log.debug('auth_res_data: ${auth_res_data}')

		session := Session{
			access_token:  auth_res_data.access_token
			refresh_token: auth_res_data.refresh_token
			expiration:    time.now().add_seconds(auth_res_data.expires_in).unix()
		}

		*h.session_chan <- session

		res.status_code = 200
		res.body = 'Authentication complete! You may now close this tab.'
	} else {
		res.status_code = 404
		res.body = 'Page not found! Expected /auth'
	}

	return res
}
