"""Prepare authorized Morevna media under the ignored DEMO directory."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import hashlib
import json
import subprocess
import tempfile

from generate_player_demo import ROOT

DIRECTORY = ROOT / '.ai-local/player-demo/real'
SUB_REVISION = 'df5af1600a9fb11e30d77f8e5486e0b4bb327398'
SUB_BASE = f'https://raw.githubusercontent.com/morevnaproject-org/subtitles-translation/{SUB_REVISION}/output/'
SUB_CHECKSUMS = {
    (3, 'eng'): '3f1e1cafd9e5db62902a97113c94aca0e4abf021caf8f0edfccef4a02d8f905c',
    (3, 'spa'): '64964adb3f8871339f8bf0f52a91ac54718745b6a56523a226c65593cd9d2445',
    (3, 'rus'): '96da9c4f97f5ead30fc3f80fa44e77f5b859bae5075cfb2087e7a77517af5d8a',
    (4, 'eng'): '1c01711500dc982457fdb1c632af79f9d0fb984d4b3fa902ea0cf578ea2580ed',
    (4, 'spa'): 'fd09ce7fefb4664e0136193a6f7076e23f1c9e18b6fb285e862fdf0209cf25e0',
    (4, 'rus'): '25013090225456e3325d7ddafd3f6467f5d60264be949dd91117d9c1d5403cd2',
}
VIDEOS = {
    (3, 'eng'): ('morevna-3.0.2-en-hq.ogv', 'f37da7202c14e711277e8b5871e7d6d90d9412ee'),
    (4, 'rus'): ('morevna-4.0.1-ru-hq.ogv', 'fa3a227ac915143b78455bda2c779c5b0808235e'),
}


def run(*args):
    return subprocess.run(args, check=True, capture_output=True).stdout


def download(name, url, maximum, checksum):
    target = DIRECTORY / name
    if target.is_symlink():
        raise RuntimeError(f'Symlinked media: {target}')
    if target.is_file():
        if digest(target) != checksum:
            raise RuntimeError(f'Unexpected cached checksum: {name}')
        return target
    with tempfile.TemporaryDirectory(dir=DIRECTORY) as work:
        candidate = Path(work) / name
        run('curl', '--fail', '--silent', '--show-error', '--location',
            '--proto', '=https', '--proto-redir', '=https', '--max-redirs', '3',
            '--connect-timeout', '10', '--max-time', '120', '--max-filesize',
            str(maximum), '--output', str(candidate), url)
        if digest(candidate) != checksum:
            raise RuntimeError(f'Unexpected downloaded checksum: {name}')
        if target.suffix == '.ogv':
            metadata = probe(candidate)
            if float(metadata['format']['duration']) < 600:
                raise RuntimeError(f'Incomplete video: {name}')
            # Also check that FFmpeg can decode this source.
            if not run('ffmpeg', '-v', 'error', '-sseof', '-15', '-i', str(candidate),
                       '-map', '0:v:0', '-frames:v', '1', '-f', 'framemd5', '-'):
                raise RuntimeError(f'Unreadable end of {name}')
        elif b' --> ' not in candidate.read_bytes():
            raise RuntimeError(f'Invalid subtitle: {name}')
        candidate.rename(target)
    return target


def digest(path):
    with path.open('rb') as source:
        return hashlib.file_digest(source, 'sha1' if path.suffix == '.ogv' else 'sha256').hexdigest()


def probe(path):
    return json.loads(run('ffprobe', '-v', 'error', '-show_format', '-show_streams',
                          '-of', 'json', str(path)))


def prepare_real_demo():
    for directory in (DIRECTORY.parent.parent, DIRECTORY.parent, DIRECTORY):
        if directory.is_symlink():
            raise RuntimeError(f'Symlinked directory: {directory}')
    DIRECTORY.mkdir(parents=True, exist_ok=True)
    with ThreadPoolExecutor(max_workers=6) as pool:
        videos = {
            key: pool.submit(download, filename,
                             f'https://archive.org/download/morevna-ep{key[0]}/{filename}',
                             65_000_000, checksum)
            for key, (filename, checksum) in VIDEOS.items()
        }
        subtitles = {
            (episode, lang): pool.submit(
                download, f'ep{episode}-{lang}.srt',
                SUB_BASE + f'morevna-ep{episode}/morevna-ep{episode}-{lang}.srt',
                300_000, SUB_CHECKSUMS[episode, lang],
            )
            for episode in (3, 4) for lang in ('eng', 'spa', 'rus')
        }
    for slot, (episode, lang) in enumerate(((3, 'eng'), (4, 'rus')), start=1):
        media = videos[episode, lang].result()
        tracks = [subtitles[episode, code].result() for code in ('eng', 'spa', 'rus')]
        target = DIRECTORY / f'episode-{slot}.mkv'
        if target.is_symlink():
            raise RuntimeError(f'Symlinked output: {target}')
        if not target.is_file():
            with tempfile.TemporaryDirectory(dir=DIRECTORY) as work:
                candidate = Path(work) / target.name
                cmd = ['ffmpeg', '-v', 'error', '-nostdin', '-i', str(media)]
                for subtitle in tracks:
                    cmd += ['-i', str(subtitle)]
                cmd += ['-map', '0:v:0', '-map', '0:a:0',
                        '-metadata:s:a:0', f'language={lang}']
                for index, code in enumerate(('eng', 'spa', 'rus')):
                    cmd += ['-map', f'{index+1}:s:0',
                            f'-metadata:s:s:{index}', f'language={code}',
                            f'-disposition:s:{index}', '0']
                cmd += ['-c', 'copy', str(candidate)]
                run(*cmd)
                candidate.rename(target)
        report = DIRECTORY / f'probe-{slot}.json'
        if report.is_symlink():
            raise RuntimeError(f'Symlinked report: {report}')
        with tempfile.TemporaryDirectory(dir=DIRECTORY) as work:
            candidate = Path(work) / report.name
            candidate.write_text(json.dumps(probe(target), indent=2), encoding='utf-8')
            candidate.replace(report)
    return DIRECTORY


if __name__ == '__main__':
    print(prepare_real_demo())
