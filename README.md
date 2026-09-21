# waybar-netlify-status

Waybar custom module that shows the latest Netlify deploy status.

Requires `curl`, `jq`, and Font Awesome 6 Free Solid in the Waybar font stack.

## Setup

```bash
cp netlify.env.example netlify.env
chmod 600 netlify.env
chmod +x netlify.sh
```

Set in `netlify.env`:

- `NETLIFY_AUTH_TOKEN`: personal access token from Netlify
- `NETLIFY_SITE_ID`: site id from Netlify site settings

## Waybar

```jsonc
"custom/netlify": {
  "exec": "/path/to/waybar-netlify-status/netlify.sh",
  "return-type": "json",
  "interval": 15,
  "tooltip": true,
  "format": "{}"
}
```

Reload:

```bash
killall -SIGUSR2 waybar
```

## Behavior

Status text comes from the Netlify deploy `state` (uppercased). `ready` is shown as `OK`.

Icons are mapped for `ready`, `enqueued`, `building`, and `error`; any other state uses a default icon.

The tooltip includes commit, branch, author, created time, and deploy time.

## License

MIT
