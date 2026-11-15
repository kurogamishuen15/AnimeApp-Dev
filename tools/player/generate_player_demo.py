"""Generate original synthetic Kongroo media in a project-local directory."""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / '.ai-local' / 'player-demo'
LANGUAGES = {
    'eng': 'Kongroo test subtitle',
    'spa': 'Subtítulo de prueba Kongroo',
    'jpn': 'コングルーのテスト字幕',
    'por': 'Legenda de teste Kongroo',
    'zho': 'Kongroo 测试字幕',
    'kor': '콩그루 테스트 자막',
}


def generate():
    if OUTPUT.parent.is_symlink() or OUTPUT.is_symlink():
        raise RuntimeError('Refusing a symlinked fixture directory')
    OUTPUT.mkdir(exist_ok=True, parents=True)
    for episode in (1, 2):
        target = OUTPUT / f'episode-{episode}.mkv'
        if target.is_symlink():
            raise RuntimeError('Refusing a symlinked fixture')
        if target.is_file():
            continue
        with tempfile.TemporaryDirectory(dir=OUTPUT) as temporary:
            work = Path(temporary)
            command = ['ffmpeg', '-hide_banner', '-loglevel', 'error', '-nostdin',
                       '-f', 'lavfi', '-i', 'testsrc2=size=480x270:rate=24']
            for frequency in (440, 550, 660):
                command += ['-f', 'lavfi', '-i', f'sine=frequency={frequency}:sample_rate=48000']
            for language, message in LANGUAGES.items():
                subtitle = work / f'{language}.srt'
                subtitle.write_text(f'1\n00:00:01,000 --> 00:00:20,000\n{message} {episode}\n',
                                    encoding='utf-8')
                command += ['-i', str(subtitle)]
            command += ['-t', '24', '-vf',
                        f"drawtext=text='DEMO {episode}   %{{pts\\:hms}}':fontsize=22:"
                        'fontcolor=white:box=1:boxcolor=black:x=14:y=14',
                        '-map', '0:v:0']
            for index, language in enumerate(('eng', 'spa', 'jpn')):
                command += ['-map', f'{index+1}:a:0', f'-metadata:s:a:{index}',
                            f'language={language}', f'-metadata:s:a:{index}',
                            'title=Synthetic test tone']
            for index, language in enumerate(LANGUAGES):
                command += ['-map', f'{index+4}:s:0', f'-metadata:s:s:{index}',
                            f'language={language}']
            candidate = work / 'fixture.mkv'
            command += ['-c:v', 'mpeg4', '-q:v', '5', '-c:a', 'aac', '-c:s', 'srt',
                        str(candidate)]
            subprocess.run(command, check=True)
            candidate.rename(target)
    return OUTPUT


if __name__ == '__main__':
    print(generate())
