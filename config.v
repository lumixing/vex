import encoding.base64
import toml

const scopes = [
	'user-library-read',
	'user-modify-playback-state',
	'user-read-playback-state',
]

struct Config {
	client_id     string
	client_secret string
	port          int = 5500
}

fn config_parse_file() Config {
	config := toml.parse_file('config.toml') or { panic('Could not parse config.toml: ${err}') }
		.reflect[Config]()

	return config
}

fn (config Config) redirect_uri() string {
	return 'http://localhost:${config.port}/auth'
}

fn (config Config) auth_hash() string {
	return base64.encode_str('${config.client_id}:${config.client_secret}')
}

fn (config Config) auth_uri() string {
	return url_encode('https://accounts.spotify.com/authorize', {
		'response_type': 'code'
		'client_id':     config.client_id
		'scope':         scopes.join('+')
		'redirect_uri':  config.redirect_uri()
	})
}
