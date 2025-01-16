struct Items {
	items []ItemTrack
	next string
	total int
}

struct ItemTrack {
	added_at string
	track Track
}

struct Track {
	album Album
	artists []Artist
	duration_ms int
	explicit bool
	external_urls ExternalURLS
	id string
	name string
	popularity int
	uri string
}

struct Album {
	artists []Artist
	externals_urls ExternalURLS
	id string
	images []Image
	name string
	release_date string
	release_date_precision string
	total_tracks int
	uri string
}

struct Artist {
	external_urls ExternalURLS
	id string
	name string
	uri string
}

struct ExternalURLS {
	spotify string
}

struct Image {
	width int
	height int
	url string
}
