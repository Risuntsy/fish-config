# Route network tools through the local SOCKS5 proxy when it is available.
set -l proxy_host localhost
set -l proxy_port 11459

if command -q nc; and nc -z -w 1 $proxy_host $proxy_port >/dev/null 2>&1
    set -l proxy_url socks5h://$proxy_host:$proxy_port

    for variable in ALL_PROXY all_proxy HTTP_PROXY http_proxy HTTPS_PROXY https_proxy
        set -gx $variable $proxy_url
    end
end
