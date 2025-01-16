import log
import json
import os
import net.http
import time

fn main() {
	mut logger := log.Log{}
	logger.set_level(.debug)
	logger.set_full_logpath('./debug.log')
	log.set_logger(logger)

	config := config_parse_file()
	mut session := Session{}

	if os.is_file('session.json') {
		log.debug('Using cached session')

		session_file := os.read_file('session.json') or {
			panic('Could not read session.json: ${err}')
		}

		session = json.decode(Session, session_file) or {
			panic('Could not parse session.json: ${err}\nConsider deleting the file to reauthenticate.')
		}
	} else {
		log.debug('No cached session! Authenticating...')

		os.open_uri(config.auth_uri()) or {
			err_msg := 'Could not automatically open link! Please manually visit to authenticate:\n${config.auth_uri()}'
			println(err_msg)
			log.error(err_msg)
		}

		mut session_chan := chan Session{}

		mut server := &http.Server{
			handler: ServerHandler{
				config:       config
				session_chan: &session_chan
			}
			addr:    ':${config.port}'
		}

		log.debug('Auth server listening on ${server.addr}')
		spawn server.listen_and_serve()

		select {
			session_value := <-session_chan {
				session = session_value
				session.write_file()
			}
		}

		log.debug('Auth server closed!')
	}

	log.debug('Session: ${session} (expires in ${(time.unix(session.expiration)-time.now()).minutes():.0} mins)')

	has_access_token_expired := time.now() > time.unix(session.expiration)
	if has_access_token_expired {
		session.refresh(config)
		session.write_file()
	}

	mut app := app_init()

	if os.is_file('items.json') {
		log.debug('Using cached items!')

		items_file := os.read_file('items.json') or {
			panic('Could not read items.json: ${err}')
		}

		app.items = json.decode(Items, items_file) or {
			panic('Could not parse items.json: ${err}\nConsider deleting the file to recache.')
		}
	} else {
		log.debug('No cached items! Caching...')
		app.items = session.get_saved_tracks()

		os.write_file('items.json', json.encode(app.items)) or {
			panic('Could not write to items.json: ${err}')
		}
	}

	
	app.tui.run()!
}
