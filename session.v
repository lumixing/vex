import os
import log
import net.http
import json
import time

const artists_field := 'artists(external_urls,id,name,uri)'
const album_field := 'album(${artists_field},external_urls,id,images,name,release_date,release_date_precision,total_tracks,uri)'
const track_field := 'track(${album_field},${artists_field},duration_ms,explicit,external_urls,id,name,popularity,uri)'
const items_fields := 'items(added_at,${track_field}),next,total'

struct Session {
	refresh_token string
mut:
	access_token  string
	expiration    i64
}

fn (session Session) write_file() {
	os.write_file('session.json', json.encode_pretty(session)) or {
		panic('Could not write to session.json: ${err}')
	}
}

fn (mut session Session) refresh(config Config) {
	log.debug('Refreshing session...')

	url := url_encode('https://accounts.spotify.com/api/token', {
		'grant_type':   'refresh_token'
		'refresh_token': session.refresh_token
	})

	mut req := http.new_request(.post, url, '')
	req.add_header(.authorization, 'Basic ${config.auth_hash()}')
	req.add_header(.content_type, 'application/x-www-form-urlencoded')
	req.add_header(.content_length, '0')

	res := req.do() or { panic('Could not request access token at ${url}: ${err}') }
	auth_res_data := json.decode(AuthResponseData, res.body) or {
		panic('Could not parse auth response body: ${res} ${err}')
	}

	log.debug('Refreshed access_token: ${session.access_token} -> ${auth_res_data.access_token}')

	session.access_token = auth_res_data.access_token
	session.expiration = time.now().add_seconds(auth_res_data.expires_in).unix()
}

struct RequestData {
	method http.Method
	url string
	body string
}

fn (session Session) request[T](rd RequestData) T {
	log.debug('Requesting ${rd}')

	mut req := http.new_request(rd.method, rd.url, rd.body)
	req.add_header(.authorization, 'Bearer ${session.access_token}')

	res := req.do() or { panic('Could not request ${rd.url}: ${err}') }
	
	return json.decode(T, res.body) or { panic('Could not parse request body: ${res} ${err}') }
}

fn (session Session) get_saved_tracks() Items {
	return session.request[Items](
		method: .get
		url: url_encode('https://api.spotify.com/v1/me/tracks', {
			'limit':  '50'
			'fields': items_fields
		})
	)
}
