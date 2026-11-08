"""Pruebas locales: procesos simulados; no acreditan Codex/Podman reales."""
import importlib.util
import contextlib
import io
import json
from pathlib import Path
import subprocess
import tempfile
import sys
import unittest
from unittest.mock import patch


SPEC = importlib.util.spec_from_file_location(
    'autonomy', Path(__file__).resolve().parents[2] / 'tools/ai/autonomy.py')
ai = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ai)


class AutonomyTests(unittest.TestCase):
    def mission(self, **updates):
        value = {'objective': 'Actualizar archivo', 'allowed_paths': ['file.txt']}
        value.update(updates)
        return value

    def load(self, data):
        with tempfile.TemporaryDirectory() as d:
            path = Path(d) / 'mission.json'
            path.write_text(json.dumps(data))
            return ai.load_mission(path)

    def test_reject_escaping_and_protected_paths(self):
        for value in ('../x', '/etc/x', '.git/config', '.ai-local/x', 'a/../x', 'x/*', 'x\\y'):
            with self.subTest(value=value), self.assertRaises(ai.Blocked):
                self.load(self.mission(allowed_paths=[value]))

    def test_limits_and_commit_fail_closed(self):
        for values in ({'max_attempts': 4}, {'max_attempts': True},
                       {'timeout_seconds': 0}, {'commit': True}, {'validation_commands': ['echo ok']}):
            with self.subTest(values=values), self.assertRaises(ai.Blocked):
                self.load(self.mission(**values))

    def test_new_paths_parse_but_execution_blocks(self):
        mission = self.load(self.mission(allowed_paths=['docs/new.md']))
        self.assertEqual(mission['allowed_paths'], ['docs/new.md'])
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            self.repo(root)
            with self.assertRaises(ai.Blocked):
                ai.inspect_repository(root, mission)

    def test_metrics_unknown_stays_null_and_usage_aggregates(self):
        self.assertIsNone(ai.parse_events('')['input_tokens'])
        events = [
            {'type': 'turn.completed', 'usage': {'input_tokens': 9, 'output_tokens': 2, 'cached_input_tokens': 3}},
            {'type': 'turn.completed', 'usage': {'input_tokens': 1, 'output_tokens': 4}},
            {'type': 'item.completed', 'item': {'type': 'command_execution'}},
            {'type': 'item.started', 'item': {'type': 'command_execution'}},
        ]
        result = ai.parse_events('\n'.join(map(json.dumps, events)) + '\nnot json')
        self.assertEqual(result, {'input_tokens': 10, 'output_tokens': 6,
                                 'cached_input_tokens': 3, 'tool_count': 1, 'invalid_json_lines': 1})

    def test_container_safety_flags(self):
        argv = ai.container_argv('sha256:abc', Path('/tmp/work'), 'test')
        for flag in ('--pull=never', '--read-only', '--userns', '--cap-drop', '--pids-limit',
                     '--image-volume=ignore', '--log-driver=none', '--http-proxy=false'):
            self.assertIn(flag, argv)
        self.assertEqual(argv[argv.index('--network') + 1], 'none')
        self.assertEqual(argv[argv.index('--memory') + 1], '1g')
        self.assertEqual(argv[argv.index('--memory-swap') + 1], '1g')
        self.assertEqual(argv[argv.index('--cpus') + 1], '1')
        self.assertEqual(argv[argv.index('--tmpfs') + 1], '/tmp:rw,nosuid,nodev,size=128m')
        self.assertNotIn('danger-full-access', argv)
        self.assertNotIn('/home', ' '.join(argv))
        self.assertIn('/tmp/work:/workspace:ro,Z', argv)
        self.assertIn('fsize=4194304:4194304', argv)
        argv = ai.container_argv('sha256:abc', Path('/tmp/work'), 'test', writable_paths=['file.txt'])
        self.assertIn('/tmp/work/file.txt:/workspace/file.txt:rw,Z', argv)

    @patch.object(ai.shutil, 'which', return_value='/usr/bin/podman')
    @patch.object(ai, 'command')
    def test_rootful_or_unavailable_podman_blocks(self, command, _):
        for output in ('{}', '{"host":{"security":{"rootless":false}}}'):
            command.return_value = subprocess.CompletedProcess([], 0, output, '')
            with self.assertRaises(ai.Blocked):
                ai.container_preflight(self.mission(image='local'))

    @patch.object(ai.shutil, 'which', return_value='/usr/bin/podman')
    @patch.object(ai, 'command')
    def test_no_broker_or_network_blocks(self, command, _):
        info = subprocess.CompletedProcess([], 0, '{"host":{"security":{"rootless":true}}}', '')
        image = subprocess.CompletedProcess([], 0,
            'sha256:abc\n' + json.dumps({'io.animeapp.ai.auth-mode': 'external-broker'}), '')
        for mission in (self.mission(image='local'), self.mission(image='local', network='bridge')):
            command.side_effect = [info, image]
            with self.assertRaises(ai.Blocked):
                ai.container_preflight(mission)

    @patch.object(ai, 'command')
    def test_timeout_force_removes_container(self, command):
        command.side_effect = [subprocess.TimeoutExpired('podman', 1),
                               subprocess.CompletedProcess([], 0, '', '')]
        with self.assertRaises(ai.Blocked):
            ai.run_container(['podman', 'run'], 1, 'test')
        self.assertEqual(command.call_args_list[-1].args[0], ['podman', 'rm', '--force', 'test'])

    def repo(self, root):
        def git(*args):
            return subprocess.run(['git', '-C', str(root), *args], check=True,
                                  capture_output=True, text=True)
        git('init', '-q')
        (root / 'file.txt').write_text('initial')
        git('add', 'file.txt')
        git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
            'commit', '-qm', 'fixture')
        return git

    def test_real_fixture_git_and_staged_guard(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            git = self.repo(root)
            ai.inspect_repository(root, self.mission())
            (root / 'file.txt').write_text('staged change')
            git('add', 'file.txt')
            with self.assertRaises(ai.Blocked):
                ai.inspect_repository(root, self.mission())

    def test_untracked_and_symlink_guards(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            self.repo(root)
            (root / 'unknown').write_text('someone else')
            with self.assertRaises(ai.Blocked):
                ai.inspect_repository(root, self.mission(allowed_paths=['unknown']))
            (root / 'docs').symlink_to('/tmp', target_is_directory=True)
            with self.assertRaises(ai.Blocked):
                ai.inspect_repository(root, self.mission(allowed_paths=['docs/new.md']))

    @patch.object(ai, 'provider_probe')
    @patch.object(ai, 'run_container')
    def test_out_of_allowlist_never_merges(self, run, probe):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            self.repo(root)
            mission = self.load(self.mission(validation_commands=[['true']]))
            _, tracked = ai.inspect_repository(root, mission)
            def malicious(argv, *args, **kwargs):
                work = Path(argv[argv.index('--volume') + 1].split(':')[0])
                (work / 'other.txt').write_text('unauthorized')
                return subprocess.CompletedProcess([], 0, '{"type":"turn.completed"}', '')
            run.side_effect = malicious
            with self.assertRaises(ai.Blocked):
                ai.execute(mission, root, tracked, 'sha256:abc', {'validation_exit_codes': []})
            self.assertEqual((root / 'file.txt').read_text(), 'initial')

    @patch.object(ai, 'provider_probe')
    @patch.object(ai, 'run_container')
    def test_existing_file_merges_after_validation(self, run, probe):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            self.repo(root)
            mission = self.load(self.mission(validation_commands=[['python3', '--version']]))
            _, tracked = ai.inspect_repository(root, mission)
            def good(argv, *args, **kwargs):
                work = Path(argv[argv.index('--volume') + 1].split(':')[0])
                (work / 'file.txt').write_text('approved')
                return subprocess.CompletedProcess([], 0, '{"type":"turn.completed"}', '')
            run.side_effect = good
            report = {'validation_exit_codes': []}
            ai.execute(mission, root, tracked, 'sha256:abc', report)
            self.assertEqual((root / 'file.txt').read_text(), 'approved')
            self.assertEqual(report['validation_exit_codes'], [0])
            self.assertEqual(run.call_count, 2)
            self.assertFalse(any(':rw,Z' in v for v in run.call_args_list[1].args[0]))

    @patch.object(ai, 'provider_probe')
    @patch.object(ai, 'run_container')
    def test_failed_validation_does_not_merge(self, run, probe):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            self.repo(root)
            mission = self.load(self.mission(validation_commands=[['false']]))
            _, tracked = ai.inspect_repository(root, mission)
            run.side_effect = [subprocess.CompletedProcess([], 0, '{"type":"turn.completed"}', ''),
                               subprocess.CompletedProcess([], 1, '', '')]
            with self.assertRaises(ai.Blocked):
                ai.execute(mission, root, tracked, 'sha256:abc', {'validation_exit_codes': []})
            self.assertFalse((root / 'docs/new.md').exists())
            self.assertEqual((root / 'file.txt').read_text(), 'initial')

    @patch.object(ai, 'provider_probe')
    @patch.object(ai, 'run_container')
    def test_no_validation_blocks_integration(self, run, probe):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            self.repo(root)
            mission = self.load(self.mission())
            _, tracked = ai.inspect_repository(root, mission)
            run.return_value = subprocess.CompletedProcess([], 0, '', '')
            with self.assertRaises(ai.Blocked):
                ai.execute(mission, root, tracked, 'sha256:abc', {'validation_exit_codes': []})
            self.assertEqual(run.call_count, 1)

    def test_sensitive_context_rejected(self):
        for value in ('.env', '.env.example', 'config/auth.json', 'private.key', '.aws/config'):
            with self.subTest(path=value), self.assertRaises(ai.Blocked):
                self.load(self.mission(context_paths=[value]))

    def test_explicit_context_excludes_other_tracked_files(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            git = self.repo(root)
            (root / '.env').write_text('EXAMPLE=not-a-real-secret')
            (root / 'context.txt').write_text('public context')
            git('add', '.env', 'context.txt')
            git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
                'commit', '-qm', 'context fixture')
            _, copied = ai.inspect_repository(root, self.mission(context_paths=['context.txt']))
            self.assertEqual(copied, ['context.txt', 'file.txt'])

    def test_real_subprocess_output_budgets_and_timeout(self):
        for stream, amount in (('stdout', ai.STDOUT_LIMIT + 1), ('stderr', ai.STDERR_LIMIT + 1)):
            with self.subTest(stream=stream), self.assertRaises(ai.Blocked):
                ai.command([sys.executable, '-c', f'import sys; sys.{stream}.write("x"*{amount})'])
        with self.assertRaises(subprocess.TimeoutExpired):
            ai.command([sys.executable, '-c', 'import time; time.sleep(10)'], timeout=0.1)
        result = ai.command([sys.executable, '-c', 'import sys; print(sys.stdin.read())'], input='ok')
        self.assertEqual(result.stdout, 'ok\n')

    def test_file_and_total_context_budgets(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            self.repo(root)
            with patch.object(ai, 'FILE_LIMIT', 3), self.assertRaises(ai.Blocked):
                ai.inspect_repository(root, self.mission())
            with patch.object(ai, 'CORPUS_LIMIT', 3), self.assertRaises(ai.Blocked):
                ai.inspect_repository(root, self.mission())
            with patch.object(ai, 'FILE_LIMIT', 3), self.assertRaises(ai.Blocked):
                ai.file_hash(root / 'file.txt')

    @patch.object(ai, 'codex_capabilities', return_value='fixture')
    @patch.object(ai, 'container_preflight', side_effect=ai.Blocked('Imagen ausente'))
    def test_plan_missing_preconditions_returns_two(self, preflight, capabilities):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            self.repo(root)
            path = root / 'mission.json'
            path.write_text(json.dumps(self.mission()))
            stream = io.StringIO()
            with contextlib.redirect_stdout(stream):
                code = ai.main(['plan', '--mission', str(path), '--root', str(root)])
            self.assertEqual(code, 2)
            self.assertEqual(json.loads(stream.getvalue())['status'], 'blocked')
            self.assertFalse((root / '.ai-local').exists())

    @patch.object(ai, 'codex_capabilities', return_value='fixture')
    @patch.object(ai, 'container_preflight', return_value='sha256:abc')
    def test_plan_never_claims_provider_ready(self, preflight, capabilities):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            self.repo(root)
            path = root / 'mission.json'
            path.write_text(json.dumps(self.mission()))
            stream = io.StringIO()
            with contextlib.redirect_stdout(stream):
                code = ai.main(['plan', '--mission', str(path), '--root', str(root)])
            self.assertEqual(code, 2)
            self.assertFalse(json.loads(stream.getvalue())['execution_ready'])

    @patch.object(ai, 'provider_probe')
    @patch.object(ai, 'run_container')
    def test_invalid_json_or_no_completion_blocks_merge(self, run, probe):
        for output in ('{"type":"turn.comp', '', '{"type":"turn.failed"}',
                       '{"type":"turn.completed"}\n{"type":"error"}'):
            with self.subTest(output=output), tempfile.TemporaryDirectory() as d:
                root = Path(d)
                self.repo(root)
                mission = self.load(self.mission(validation_commands=[['true']]))
                _, tracked = ai.inspect_repository(root, mission)
                run.return_value = subprocess.CompletedProcess([], 0, output, '')
                with self.assertRaises(ai.Blocked):
                    ai.execute(mission, root, tracked, 'sha256:abc', {'validation_exit_codes': []})
                self.assertEqual((root / 'file.txt').read_text(), 'initial')

    @patch.object(ai, 'run_container')
    def test_provider_probe_audits_image_cli_and_blocks_failed_health(self, run):
        ok = lambda output: subprocess.CompletedProcess([], 0, output, '')
        run.side_effect = [ok('--ask-for-approval'), ok('--json --ephemeral --sandbox --skip-git-repo-check'),
                           ok('--json --network-only'), subprocess.CompletedProcess([], 1, '{}', '')]
        with self.assertRaises(ai.Blocked):
            ai.provider_probe('sha256:abc', Path('/tmp/work'), 'bridge', 5)
        self.assertEqual(run.call_count, 4)
        self.assertEqual(run.call_args_list[-1].args[0][-3:], ['doctor', '--json', '--network-only'])

    @patch.object(ai, 'run_container')
    def test_provider_probe_missing_flags_blocks_before_network(self, run):
        run.return_value = subprocess.CompletedProcess([], 0, 'old cli', '')
        with self.assertRaises(ai.Blocked):
            ai.provider_probe('sha256:abc', Path('/tmp/work'), 'bridge', 5)
        self.assertEqual(run.call_count, 1)


if __name__ == '__main__':
    unittest.main()
