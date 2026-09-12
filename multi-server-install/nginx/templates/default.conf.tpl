# Per-domain vhosts are rendered by 20-envsubst-on-templates.sh
# from *.conf.template into /etc/nginx/conf.d/. This file exists only
# because the image entrypoint runs `jinja2` against default.conf.tpl
# and refuses to start without it.
