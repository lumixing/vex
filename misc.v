fn url_encode(url string, queries map[string]string) string {
	mut queries_str := []string{}

	for key, value in queries {
		queries_str << '${key}=${value}'
	}

	return '${url}?${queries_str.join('&')}'
}
