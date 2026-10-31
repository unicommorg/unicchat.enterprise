#!/usr/bin/env python3
"""Read-only KBT dependency preflight and Prometheus exporter (stdlib only)."""
import argparse
import json
import os
import socket
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlsplit
from urllib.request import HTTPRedirectHandler, ProxyHandler, Request, build_opener

CHECKS = ("vault", "config", "mongo_tcp", "minio_ready")


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def request(url, token=None):
    # Never forward Vault credentials through a redirect or an ambient proxy.
    parsed = urlsplit(url)
    if parsed.scheme not in ("http", "https") or not parsed.hostname or parsed.username:
        raise ValueError("invalid HTTP endpoint")
    headers = {"Authorization": "Bearer " + token} if token else {}
    with build_opener(NoRedirect(), ProxyHandler({})).open(
        Request(url, headers=headers), timeout=5
    ) as response:
        if response.status != 200:
            raise ValueError("unexpected HTTP status")
        body = response.read(1024 * 1024 + 1)
        if len(body) > 1024 * 1024:
            raise ValueError("response too large")
        return body.decode("utf-8")


def endpoint(value, scheme, default_port):
    parsed = urlsplit(value if "://" in value else scheme + "://" + value)
    if parsed.scheme != scheme or not parsed.hostname or "," in parsed.netloc:
        raise ValueError("unsupported endpoint")
    return parsed.hostname.lower(), parsed.port or default_port


def check(env=None):
    env = os.environ if env is None else env
    result = dict.fromkeys(CHECKS, 0)
    try:
        vault = env["API_VAULT_URL"].rstrip("/") + "/"
        token = request(vault + "api/token/0f8e160416b94225a73f86ac23b9118b?username=KBTservice").strip()
        if not token or "\n" in token or "\r" in token:
            return result
        meta = json.loads(request(vault + "api/Secrets/KBTConfigs/meta", token))
        if not isinstance(meta, dict):
            return result
        result["vault"] = 1
        mongo = endpoint(meta["MongoCS"], "mongodb", 27017)
        minio = endpoint(meta["MinioHost"], "http", 80)
        expected_mongo = (env["KBT_MONGO_HOST"].lower(), int(env["MONGODB_PORT_NUMBER"]))
        expected_minio = endpoint(env["KBT_MINIO_HOST"], "http", 80)
        result["config"] = int(mongo == expected_mongo and minio == expected_minio)
    except (OSError, ValueError, KeyError, TypeError):
        # Exceptions can contain secrets/URLs. Only fixed check names are emitted.
        return result
    try:
        with socket.create_connection(mongo, timeout=5):
            result["mongo_tcp"] = 1
    except OSError:
        pass
    try:
        host = "[" + minio[0] + "]" if ":" in minio[0] else minio[0]
        request("http://" + host + ":" + str(minio[1]) + "/minio/health/ready")
        result["minio_ready"] = 1
    except (OSError, ValueError):
        pass
    return result


def metrics(result, timestamp):
    lines = ["# HELP unicchat_dependency_ok Dependency check: 1 success, 0 failure.",
             "# TYPE unicchat_dependency_ok gauge"]
    lines += [f'unicchat_dependency_ok{{dependency="{name}"}} {result[name]}' for name in CHECKS]
    lines += ["# HELP unicchat_dependency_check_timestamp_seconds Last completed check.",
              "# TYPE unicchat_dependency_check_timestamp_seconds gauge",
              f"unicchat_dependency_check_timestamp_seconds {timestamp}"]
    return "\n".join(lines) + "\n"


def serve():
    snapshot = [metrics(dict.fromkeys(CHECKS, 0), 0)]

    def collect():
        while True:
            snapshot[0] = metrics(check(), time.time())
            time.sleep(30)

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path != "/metrics":
                self.send_error(404)
                return
            data = snapshot[0].encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def log_message(self, *_):
            pass

    threading.Thread(target=collect, daemon=True).start()
    HTTPServer(("0.0.0.0", 9808), Handler).serve_forever()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--once", action="store_true")
    mode.add_argument("--serve", action="store_true")
    args = parser.parse_args()
    if args.serve:
        serve()
        return 0
    result = check()
    for name, ok in result.items():
        print(name + (": OK" if ok else ": FAILED"))
    return 0 if all(result.values()) else 1


if __name__ == "__main__":
    raise SystemExit(main())
