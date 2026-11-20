#!/usr/bin/env python3
"""Exercise real HTTP range support, ignored ranges and checksum failures."""
import hashlib
import http.server
import pathlib
import subprocess
import tempfile
import threading

root = pathlib.Path(__file__).resolve().parents[1]
payload = bytes(range(256)) * 128
checksum = hashlib.sha256(payload).hexdigest()
checksum512 = hashlib.sha512(payload).hexdigest()


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        data = payload
        if self.path == '/range':
            start, end = map(int, self.headers['Range'].removeprefix('bytes=').split('-'))
            data = payload[start:end + 1]
            self.send_response(206)
            self.send_header('Content-Range', f'bytes {start}-{end}/{len(payload)}')
        else:
            self.send_response(200)
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        try:
            self.wfile.write(data)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def log_message(self, *args):
        pass


with http.server.ThreadingHTTPServer(('127.0.0.1', 0), Handler) as server:
    worker = threading.Thread(target=server.serve_forever, daemon=True)
    worker.start()
    with tempfile.TemporaryDirectory() as temp:
        for endpoint, digest, expected in (('range', checksum, True), ('ignore', checksum, False),
                                           ('range', '0' * 64, False), ('range', checksum512, True),
                                           ('range', '0' * 128, False)):
            output = pathlib.Path(temp) / 'package.deb'
            if output.exists():
                output.unlink()
            result = subprocess.run(['bash', '-c', 'source "$1/lib/network.sh"; download_ranges_verified "$2" "$3" "$4" "$5"', '_', str(root), f'http://127.0.0.1:{server.server_port}/{endpoint}', digest, str(len(payload)), str(output)], capture_output=True)
            assert (result.returncode == 0) == expected, result.stderr.decode()
            assert output.exists() == expected
            if expected:
                assert output.read_bytes() == payload
        output = pathlib.Path(temp) / 'native.tgz'
        command = 'for lib in logging common network; do source "$1/lib/$lib.sh"; done; download_verified "$2" "$3" "$4"'
        result = subprocess.run(['bash', '-c', command, '_', str(root),
                                 f'http://127.0.0.1:{server.server_port}/ignore',
                                 checksum512, str(output)], capture_output=True)
        assert result.returncode == 0, result.stderr.decode()
        assert output.read_bytes() == payload
        # A verified SHA512 cache must work without any server connection.
        result = subprocess.run(['bash', '-c', command, '_', str(root),
                                 'http://127.0.0.1:1/unavailable', checksum512,
                                 str(output)], capture_output=True)
        assert result.returncode == 0, result.stderr.decode()
    server.shutdown()
print('HTTP ranges, ignored-range rejection and checksum protection: passed')
