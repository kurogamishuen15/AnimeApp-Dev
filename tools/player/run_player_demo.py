#!/usr/bin/env python3
"""Launch the built Linux player and own its three loopback HTTP servers."""
import argparse
from contextlib import ExitStack, contextmanager
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import os
import re
import signal
import subprocess
from threading import Thread

from generate_player_demo import ROOT, generate
from prepare_real_player_demo import prepare_real_demo


@contextmanager
def mirror(directory, fail=False):
    class Handler(BaseHTTPRequestHandler):
        def do_HEAD(self):
            self.serve(False)

        def do_GET(self):
            self.serve(True)

        def serve(self, send_body):
            if self.path not in ('/episode-1.mkv', '/episode-2.mkv'):
                self.send_error(404)
                return
            if fail:
                self.send_error(503)
                return
            media = directory / self.path[1:]
            size = media.stat().st_size
            start, end = 0, size - 1
            requested = self.headers.get('Range')
            if requested is not None:
                match = re.fullmatch(r'bytes=([0-9]{1,20})-([0-9]{0,20})', requested)
                if match:
                    start = int(match[1])
                    end = min(int(match[2]), end) if match[2] else end
                if not match or start > end:
                    self.send_response(416)
                    self.send_header('Content-Range', f'bytes */{size}')
                    self.send_header('Content-Length', '0')
                    self.end_headers()
                    return
            self.send_response(206 if requested else 200)
            self.send_header('Content-Type', 'video/x-matroska')
            self.send_header('Accept-Ranges', 'bytes')
            self.send_header('Content-Length', str(end - start + 1))
            if requested:
                self.send_header('Content-Range', f'bytes {start}-{end}/{size}')
            self.end_headers()
            if send_body:
                try:
                    with media.open('rb') as source:
                        source.seek(start)
                        remaining = end - start + 1
                        while remaining:
                            block = source.read(min(remaining, 65536))
                            if not block:
                                break
                            self.wfile.write(block)
                            remaining -= len(block)
                except (BrokenPipeError, ConnectionResetError):
                    pass

    with ThreadingHTTPServer(('127.0.0.1', 0), Handler) as server:
        worker = Thread(target=server.serve_forever, daemon=True)
        worker.start()
        try:
            yield server.server_port
        finally:
            server.shutdown()
            worker.join()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    playback = parser.add_mutually_exclusive_group()
    playback.add_argument('--autoplay', action='store_true', help='start playback immediately')
    playback.add_argument('--paused', action='store_true', help='wait for Play')
    parser.add_argument('--synthetic', action='store_true', help='use deterministic fixtures for development tests')
    parser.add_argument('--subtitles', choices=('eng', 'spa', 'rus'), help='select a published subtitle on startup')
    parser.add_argument('--start-at', type=int, help='initial position in seconds')
    parser.add_argument('--nerd', action='store_true', help='show native diagnostics overlay on startup')
    parser.add_argument('--no-build', action='store_true', help='reuse the existing release bundle for repeatable measurements')
    parser.add_argument('--fit', choices=('contain', 'cover', 'fill', 'original'),
                        help='initial video scaling for visual checks')
    parser.add_argument('--aspect', choices=('auto', '16:9', '4:3', '21:9'),
                        help='initial display aspect ratio for visual checks')
    args = parser.parse_args()
    if (args.start_at or 0) < 0 or (args.synthetic and args.subtitles):
        parser.error('Use a nonnegative start and real media for published subtitles.')
    autoplay = args.autoplay or (
        not args.paused and not args.synthetic
        and args.start_at is None and args.subtitles is None
    )
    environment = os.environ.copy()
    environment.pop('FLUTTER_ROOT', None)
    environment.update(PUB_CACHE=str(ROOT / '.ai-local/pub-cache'))
    for relative in ('.ai-local/pub-cache', '.ai-local/player-demo',
                     '.ai-local/toolchains/flutter-3.47.9/bin/flutter',
                     'app/build/linux/x64/release/bundle/anime_app'):
        candidate = ROOT
        for part in relative.split('/'):
            candidate /= part
            if candidate.is_symlink():
                parser.error(f'Refusing symlinked path: {candidate}')
    for key in tuple(environment):
        if key.lower() in ('http_proxy', 'https_proxy', 'all_proxy', 'no_proxy'):
            del environment[key]
    environment.update(no_proxy='127.0.0.1', NO_PROXY='127.0.0.1')
    if not args.no_build:
        subprocess.run([
            str(ROOT / '.ai-local/toolchains/flutter-3.47.9/bin/flutter'),
            'build', 'linux', '--release', '--no-pub', '--no-tree-shake-icons', '-t', 'lib/main_player_spike.dart',
        ], cwd=ROOT / 'app', env=environment, check=True)
    binary = ROOT / 'app/build/linux/x64/release/bundle/anime_app'
    if not binary.is_file():
        parser.error('No Linux release bundle found after building.')
    directory = generate() if args.synthetic else prepare_real_demo()
    with ExitStack() as stack:
        ports = [stack.enter_context(mirror(directory, fail=index == 2))
                 for index in range(3)]
        environment.update(
            KONGROO_F2_2_SPIKE='1',
            KONGROO_PROJECT_ROOT=str(ROOT),
            KONGROO_DEMO_SUBTITLES=args.subtitles or '',
            KONGROO_DEMO_START=str(args.start_at or 0),
            KONGROO_DEMO_REAL_MEDIA='0' if args.synthetic else '1',
            KONGROO_DEMO_PORTS=','.join(map(str, ports)),
            KONGROO_DEMO_AUTOPLAY='1' if autoplay else '0',
            KONGROO_DEMO_SHOW_NERD='1' if args.nerd else '0',
            KONGROO_DEMO_FIT=args.fit or '',
            KONGROO_DEMO_ASPECT=args.aspect or '',
        )
        print(f'Demo loopback ports A/B/C: {ports}', flush=True)
        with subprocess.Popen([str(binary)], env=environment, cwd=ROOT / 'app') as player:
            def terminate(_number, _frame):
                player.terminate()
            signal.signal(signal.SIGTERM, terminate)
            try:
                return player.wait()
            except KeyboardInterrupt:
                player.terminate()
                return player.wait()


if __name__ == '__main__':
    raise SystemExit(main())
