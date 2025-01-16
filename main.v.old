import term.ui as tui
import net.http
import toml
import os
import encoding.base64
import json
import log
import term
import time
import math

struct App {
mut:
	tui           &tui.Context = unsafe { nil }
	counter       int
	access_token  string
	tracks        []TrackItem
	current_track ?Track
}

struct TrackItems {
	total int
	items []TrackItem
}

struct TrackItem {
	added_at string
	track    Track
}

struct Track {
	id          string
	uri         string
	name        string
	album       Album
	artists     []Artist
	duration_ms int
}

struct Album {
	name string
}

struct Artist {
	name string
}

fn event(e &tui.Event, x voidptr) {
	if e.typ == .key_down && e.code == .escape {
		exit(0)
	}

	mut app := unsafe { &App(x) }

	if e.typ == .key_down && (e.code == .w || e.code == .up) {
		app.counter -= 1
		if app.counter < 0 {
			app.counter = app.tracks.len - 1
		}

		if e.modifiers.has(.ctrl) {
			app.counter = 0
		}
	}

	if e.typ == .key_down && (e.code == .s || e.code == .down) {
		app.counter += 1
		if app.counter >= app.tracks.len {
			app.counter = 0
		}

		if e.modifiers.has(.ctrl) {
			app.counter = app.tracks.len - 1
		}
	}

	if e.typ == .key_down && e.code == .enter {
		url := url_encode('https://api.spotify.com/v1/me/player/play', {})

		body := '{"uris":["${app.tracks[app.counter].track.uri}"]}'
		mut req := http.new_request(.put, url, body)
		req.add_header(.content_type, 'application/json')
		req.add_header(.authorization, 'Bearer ${app.access_token}')

		res := req.do() or { panic(err) }
		log.debug('playing ${body} ${res}')

		app.current_track = app.tracks[app.counter].track
	}

	if e.typ == .mouse_down {
		app.counter = e.y - 1
	}
}

fn is_wide_char(r rune) bool {
	ranges := [
		[0x1100, 0x115F],
		[0x2E80, 0x303E],
		[0x3040, 0xA4CF],
		[0xAC00, 0xD7A3],
		[0xF900, 0xFAFF],
		[0xFE10, 0xFE19],
		[0xFE30, 0xFE6F],
		[0xFF00, 0xFF60],
		[0xFFE0, 0xFFE6],
		[0x20000, 0x2FFFD],
		[0x30000, 0x3FFFD],
	]

	for range in ranges {
		if r >= range[0] && r <= range[1] {
			return true
		}
	}
	return false
}

pub fn get_string_width(s string) int {
	mut width := 0
	for c in s.runes() {
		if is_wide_char(c) {
			width += 2
		} else {
			width += 1
		}
	}
	return width
}

fn str_clamp(_str string, max_len int) string {
	if _str.len_utf8() <= max_len {
		mut str := _str

		// mut len := _str.len_utf8()
		// if _str.len != _str.len_utf8() {
		// 	len *= 2
		// }
		mut len := get_string_width(_str)

		for _ in 0 .. max_len - len {
			str += ' '
		}

		return str
	}

	return '${_str.substr(0, max_len - 1)}…'
}

fn ms_to_time_str(ms int) string {
	min_raw := f32(ms) / 1000 / 60
	min := int(math.floor(min_raw))
	sec := int(math.fmod(min_raw, 1) * 60)

	return '${min}:${sec:02}'
}

fn frame(_x voidptr) {
	mut app := unsafe { &App(_x) }

	app.tui.clear()
	x, y := term.get_terminal_size()

	if app.tracks.len == 0 {
		app.tui.draw_text(0, 1, 'press enter to get liked song...')
		app.tui.draw_text(0, 2, 'size (${x}, ${y})')
	} else {
		if current_track := app.current_track {
			app.tui.draw_text(0, y, '${str_clamp(current_track.name, 20)} ${str_clamp(current_track.artists[0].name,
				20)} ${ms_to_time_str(current_track.duration_ms)}')
		} else {
			app.tui.draw_text(0, y, 'no track playing!')
		}

		mut mode := '???'
		if app.counter in 0..y / 2 - 3 {
			mode = 'begin'
		} else if app.counter in app.tracks.len - y / 2..app.tracks.len {
			mode = 'end'
		} else {
			mode = 'middle'
		}

		app.tui.draw_text(0, y - 1, '${mode} ${x} ${y} (${x / 2} ${y / 2}) ${time.now().unix_milli()}')

		// for i, item in app.tracks {
		if mode == 'begin' {
			for item_idx in 0 .. y - 3 {
				if item_idx >= app.tracks.len {
					break
				}

				item := app.tracks[item_idx]

				if app.counter == item_idx {
					app.tui.set_color(r: 0, g: 0, b: 0)
					app.tui.set_bg_color(r: 255, g: 255, b: 255)
				} else {
					app.tui.reset_color()
					app.tui.reset_bg_color()
				}

				track_name := item.track.name
				artist_name := item.track.artists[0].name

				// app.tui.draw_text(0, i + 1, '${str_clamp(track_name, x / 3 * 2)} ${str_clamp(artist_name,
				// 	x - x / 3 * 2 - 1)}')
				app.tui.draw_text(0, item_idx + 1, '${item_idx + 1:3} ${str_clamp(track_name,
					20)} ${str_clamp(artist_name, 20)} ${ms_to_time_str(item.track.duration_ms)}')
			}
		} else if mode == 'middle' {
			mut j := 0

			for item_idx in app.counter - y / 2 + 3 .. app.counter + y / 2 + 1 {
				item := app.tracks[item_idx]

				if app.counter == item_idx {
					app.tui.set_color(r: 0, g: 0, b: 0)
					app.tui.set_bg_color(r: 255, g: 255, b: 255)
				} else {
					app.tui.reset_color()
					app.tui.reset_bg_color()
				}

				track_name := item.track.name
				artist_name := item.track.artists[0].name

				// app.tui.draw_text(0, i + 1, '${str_clamp(track_name, x / 3 * 2)} ${str_clamp(artist_name,
				// 	x - x / 3 * 2 - 1)}')
				app.tui.draw_text(0, j + 1, '${item_idx + 1:3} ${str_clamp(track_name,
					20)} ${str_clamp(artist_name, 20)} ${ms_to_time_str(item.track.duration_ms)}')

				j += 1
			}
		} else if mode == 'end' {
			mut j := 0

			for item_idx in app.tracks.len - y + 3 .. app.tracks.len {
				if item_idx < 0 {
					continue
				}

				item := app.tracks[item_idx]

				if app.counter == item_idx {
					app.tui.set_color(r: 0, g: 0, b: 0)
					app.tui.set_bg_color(r: 255, g: 255, b: 255)
				} else {
					app.tui.reset_color()
					app.tui.reset_bg_color()
				}

				track_name := item.track.name
				artist_name := item.track.artists[0].name

				// app.tui.draw_text(0, i + 1, '${str_clamp(track_name, x / 3 * 2)} ${str_clamp(artist_name,
				// 	x - x / 3 * 2 - 1)}')
				app.tui.draw_text(0, j + 1, '${item_idx + 1:3} ${str_clamp(track_name,
					20)} ${str_clamp(artist_name, 20)} ${ms_to_time_str(item.track.duration_ms)}')

				j += 1
			}
		}
	}

	app.tui.set_cursor_position(0, 0)
	app.tui.reset()
	app.tui.flush()
}

struct Config {
	client_id     string
	client_secret string
	port          int = 5500
	scopes        []string
}

fn (config Config) redirect_uri() string {
	return 'http://localhost:${config.port}/auth'
}

struct Handler {
	config Config
mut:
	app  &App
	done &chan string
}

struct AuthResponse {
	access_token  string
	refresh_token string
	expires_in    int
}

fn (mut h Handler) handle(req http.Request) http.Response {
	mut res := http.Response{
		header: http.new_header_from_map({
			.content_type: 'text/plain'
		})
	}
	mut status_code := 200

	if req.url.starts_with('/auth') {
		code := req.url.split('=')[1]

		url := url_encode('https://accounts.spotify.com/api/token', {
			'grant_type':   'authorization_code'
			'redirect_uri': h.config.redirect_uri()
			'code':         code
		})

		auth_hash := base64.encode_str('${h.config.client_id}:${h.config.client_secret}')

		mut new_req := http.new_request(.post, url, '')
		new_req.add_header(.authorization, 'Basic ${auth_hash}')
		new_req.add_header(.content_type, 'application/x-www-form-urlencoded')
		new_req.add_header(.content_length, '0')
		new_res := new_req.do() or { panic(err) }

		auth_res := json.decode(AuthResponse, new_res.body) or { panic(err) }
		log.debug(auth_res.access_token)
		h.app.access_token = auth_res.access_token

		*h.done <- auth_res.access_token
	}

	res.status_code = status_code

	return res
}

fn url_encode(url string, queries map[string]string) string {
	mut queries_str := []string{}

	for key, value in queries {
		queries_str << '${key}=${value}'
	}

	return '${url}?${queries_str.join('&')}'
}

fn main() {
	mut logger := log.Log{}
	logger.set_level(.debug)
	logger.set_full_logpath('./debug.log')
	log.set_logger(logger)

	config := toml.parse_file('config.toml') or { panic('Could not parse config.toml: ${err}') }
		.reflect[Config]()
	log.debug('${config}')

	mut app := &App{}

	if os.is_file('access_token.txt') {
		// todo: check expriration
		cached_access_token := os.read_file('access_token.txt')!
		app.access_token = cached_access_token
	} else {
		os.open_uri(url_encode('https://accounts.spotify.com/authorize', {
			'response_type': 'code'
			'client_id':     config.client_id
			'scope':         config.scopes.join('+')
			'redirect_uri':  config.redirect_uri()
		}))!

		mut done := chan string{}

		mut handler := Handler{
			config: config
			app:    app
			done:   &done
		}

		mut server := &http.Server{
			handler: handler
			addr:    ':${config.port}'
		}

		spawn server.listen_and_serve()

		select {
			idk := <-done {
				os.write_file('access_token.txt', idk)!
				app.access_token = idk
			}
		}
	}

	spawn fn (mut app App) {
		mut last := time.now()
		for {
			if time.since(last).seconds() >= 3 {
				last = time.now()

				url := url_encode('https://api.spotify.com/v1/me/player', {
					'fields': 'item'
				})

				mut req := http.new_request(.get, url, '')
				req.add_header(.authorization, 'Bearer ${app.access_token}')

				res := req.do() or { panic(err) }

				current_track := json.decode(struct {
					item Track
				}, res.body) or { panic(err) }

				// log.debug('tick! ${res}')
				// log.debug('tick2!! ${current_track}')
				app.current_track = current_track.item
			}
		}
	}(mut app)

	url := url_encode('https://api.spotify.com/v1/me/tracks', {
		'limit':  '50'
		'fields': 'total,items(added_at,track(id,uri,name,duration_ms,artists.name,album.name))'
	})

	mut req := http.new_request(.get, url, '')
	req.add_header(.authorization, 'Bearer ${app.access_token}')

	// new_req.add_header(.content_length, '0')
	res := req.do() or { panic(err) }
	log.debug('${res}')

	track_items := json.decode(TrackItems, res.body) or { panic(err) }
	app.tracks = track_items.items

	app.tui = tui.init(
		user_data:   app
		event_fn:    event
		frame_fn:    frame
		hide_cursor: true
	)

	app.tui.run()!
}
