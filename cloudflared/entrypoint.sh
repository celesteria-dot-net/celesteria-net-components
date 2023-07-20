#!/bin/ash
set -e

domain=celesteria.net
tunnel_name=celesteria-net-argo

# list tunnel information in yaml format.
# A typical output is
# - id: ********-****-****-****-************
#   name: ********
#   createdat: ****-**-**T**:**:**.******Z
#   deletedat: 2000-01-01T00:00:00Z
#   connections: []
list_tunnel_as_yaml () {
  cloudflared tunnel list --name $tunnel_name --output yaml
}

recreate_tunnel () {
  cloudflared tunnel cleanup $tunnel_name
  cloudflared tunnel delete $tunnel_name || true
  cloudflared tunnel create $tunnel_name
}

get_available_tunnel_id () {
  list_tunnel_as_yaml | yq eval '.[0].id' -
}

ensure_tunnel_exists_and_we_have_access () {
  # recreate tunnel if we don't have a tunnel or the credential to the tunnel
  if [ $(list_tunnel_as_yaml | yq eval '. | length' -) == "0" ] ||\
     [ ! -f "/root/.cloudflared/$(get_available_tunnel_id).json" ]; then
    recreate_tunnel
  fi
}

# login if cert.pem not found
if [ ! -f ~/.cloudflared/cert.pem ]; then
  cloudflared tunnel login
fi

ensure_tunnel_exists_and_we_have_access

tunnel_id=$(get_available_tunnel_id)

# re-route all domains in ingress-rules to this tunnel
yq e ".ingress.[].hostname | select(. != null)" /tmp/tunnel-config.yaml \
  | xargs -n 1 cloudflared tunnel route --overwrite-dns dns $tunnel_id $hostname

# start the tunnel
cloudflared tunnel --config /tmp/tunnel-config.yaml --no-autoupdate run $tunnel_id
