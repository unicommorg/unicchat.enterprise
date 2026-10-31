import contextlib
import io
import json
import subprocess
import unittest
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from unittest.mock import patch
import dependency_probe as probe
import tasker_recovery as recovery

ENV = {"API_VAULT_URL": "http://vault/", "KBT_MONGO_HOST": "mongo", "MONGODB_PORT_NUMBER": "27017", "KBT_MINIO_HOST": "minio:9000"}
META = {"MongoCS": "mongodb://user:private@mongo:27017/tasker", "MinioHost": "minio:9000", "MinioPass": "private"}


class ProbeTests(unittest.TestCase):
    def evaluate(self, meta=None, minio_error=None, mongo_error=None):
        replies = ["private-token", json.dumps(META if meta is None else meta), minio_error or ""]
        with patch.object(probe, "request", side_effect=replies), patch.object(probe.socket, "create_connection", side_effect=mongo_error) as connect:
            if mongo_error is None:
                connect.return_value = contextlib.nullcontext()
            return probe.check(ENV)

    def test_healthy(self):
        self.assertTrue(all(self.evaluate().values()))

    def test_mongo_failure_does_not_hide_minio(self):
        self.assertEqual(self.evaluate(mongo_error=OSError("secret")), {"vault": 1, "config": 1, "mongo_tcp": 0, "minio_ready": 1})

    def test_minio_failure(self):
        self.assertEqual(self.evaluate(minio_error=OSError("secret"))["minio_ready"], 0)

    def test_existing_secret_mismatch_blocks(self):
        result = self.evaluate({**META, "MinioHost": "old-minio:9000"})
        self.assertEqual(result["config"], 0)
        self.assertEqual(result["minio_ready"], 1)

    def test_missing_secret_and_wrong_shape_fail_closed(self):
        for meta in ({}, [], {"MongoCS": None}, {**META, "MinioHost": "https://minio:9000"}):
            self.assertFalse(all(self.evaluate(meta).values()))

    def test_vault_error_does_not_leak(self):
        out = io.StringIO()
        with patch.object(probe, "request", side_effect=OSError("private-token")), contextlib.redirect_stdout(out):
            result = probe.check(ENV)
        self.assertFalse(any(result.values()))
        self.assertNotIn("private", out.getvalue() + probe.metrics(result, 123))

    def test_mongo_multi_host_rejected(self):
        with self.assertRaises(ValueError):
            probe.endpoint("mongodb://user:secret@one:27017,two:27017/db", "mongodb", 27017)

    def test_failed_gate_never_recreates(self):
        with patch.object(recovery.subprocess, "run", return_value=subprocess.CompletedProcess([], 1)) as run:
            self.assertEqual(recovery.recover(["docker", "compose"], True), 1)
            self.assertEqual(run.call_count, 1)

    def test_check_only_never_recreates(self):
        with patch.object(recovery.subprocess, "run", return_value=subprocess.CompletedProcess([], 0)) as run:
            self.assertEqual(recovery.recover(["docker", "compose"]), 0)
            self.assertEqual(run.call_count, 1)

    def test_success_gate_recreates_only_tasker(self):
        with patch.object(recovery.subprocess, "run", return_value=subprocess.CompletedProcess([], 0)) as run:
            self.assertEqual(recovery.recover(["docker", "compose"], True), 0)
            self.assertEqual(run.call_args_list[1].args[0], ["docker", "compose", "up", "-d", "--no-deps", "--force-recreate", "unicchat-tasker"])


class HTTPTests(unittest.TestCase):
    def setUp(self):
        self.minio_status = 200
        self.redirect = False
        self.authorized = False
        test = self

        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                status, body = 200, b""
                if self.path.startswith("/api/token/"):
                    body = b"test-token"
                elif self.path == "/api/Secrets/KBTConfigs/meta":
                    test.authorized = self.headers.get("Authorization") == "Bearer test-token"
                    body = json.dumps({"MongoCS": "mongodb://user:secret@127.0.0.1:" + str(self.server.server_port) + "/db", "MinioHost": "127.0.0.1:" + str(self.server.server_port)}).encode()
                elif self.path == "/minio/health/ready":
                    status = test.minio_status
                if test.redirect:
                    status = 302
                self.send_response(status)
                if test.redirect:
                    self.send_header("Location", "/elsewhere")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)

            def log_message(self, *_):
                pass

        self.server = HTTPServer(("127.0.0.1", 0), Handler)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        port = str(self.server.server_port)
        self.env = {"API_VAULT_URL": "http://127.0.0.1:" + port, "KBT_MONGO_HOST": "127.0.0.1", "MONGODB_PORT_NUMBER": port, "KBT_MINIO_HOST": "127.0.0.1:" + port}

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()

    def test_real_http_and_tcp(self):
        self.assertTrue(all(probe.check(self.env).values()))
        self.assertTrue(self.authorized)

    def test_minio_503_is_failure(self):
        self.minio_status = 503
        self.assertEqual(probe.check(self.env)["minio_ready"], 0)

    def test_redirect_is_not_followed(self):
        self.redirect = True
        with self.assertRaises(OSError):
            probe.request(self.env["API_VAULT_URL"], "test-token")


if __name__ == "__main__":
    unittest.main()
