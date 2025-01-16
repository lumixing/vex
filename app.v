import term.ui as tui

struct App {
mut:
	tui &tui.Context = unsafe { nil }
	items Items
}

fn app_init() &App {
	mut app := &App{}

	app.tui = tui.init(
		user_data:   app
		event_fn:    event
		frame_fn:    frame
		hide_cursor: true
	)

	return app
}

fn event(e &tui.Event, _x voidptr) {
	// mut app := unsafe { &App(_x) }
	if e.typ == .key_down && e.code == .escape {
		exit(0)
	}
}

fn frame(_x voidptr) {
	mut app := unsafe { &App(_x) }

	app.tui.clear()

	defer {
		app.tui.reset()
		app.tui.flush()
	}


	for i, item in app.items.items {
		track := item.track
		app.tui.draw_text(0, i+1, '${track.name} by ${track.artists[0].name}')
	}
}
