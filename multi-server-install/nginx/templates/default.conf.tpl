# Per-domain vhosts are rendered by nginx-config-init (envsubst in the
# container) into /etc/nginx/conf.d/{00-app,10-documentserver,20-minio}.conf.
# This file exists only because the image entrypoint runs `jinja2` against
# default.conf.tpl and refuses to start without it. Do not put server {} here.
