import hashlib
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

TOOLS = Path(__file__).resolve().parents[2] / 'tools/ai'
sys.path.insert(0, str(TOOLS))
import evaluate


class BackupEvaluationTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.backup = self.root / '.ai-local/backups/initial-20261107'
        self.backup.mkdir(parents=True)

    def manifest(self, values):
        (self.backup / 'SHA256.json').write_text(json.dumps(values))

    def test_valid_and_corrupted_copy(self):
        source = self.backup / 'AGENTS.md'
        source.write_text('instrucciones originales')
        self.manifest({'AGENTS.md': hashlib.sha256(source.read_bytes()).hexdigest()})
        self.assertTrue(evaluate.validate_backups(self.root))
        source.write_text('alterado')
        self.assertFalse(evaluate.validate_backups(self.root))

    def test_manifest_escape_and_symlink_rejected(self):
        for path in ('../../AGENTS.md', '/tmp/AGENTS.md', '.codex/../AGENTS.md'):
            self.manifest({path: '0' * 64})
            self.assertFalse(evaluate.validate_backups(self.root))
        target = self.root / 'outside.txt'
        target.write_text('fuera del respaldo')
        (self.backup / 'AGENTS.md').symlink_to(target)
        self.manifest({'AGENTS.md': hashlib.sha256(target.read_bytes()).hexdigest()})
        self.assertFalse(evaluate.validate_backups(self.root))

    def test_missing_backup_is_unknown_not_success(self):
        self.assertIsNone(evaluate.validate_backups(self.root))

    def test_corrupt_backup_fails_global_evaluation(self):
        report = {'recovery_cases': [{'passed': True}], 'memory_lint_issues': [],
                  'toolchain_fixture': {'passed': True}, 'backup_hashes_valid': False}
        self.assertFalse(evaluate.successful(report))
        report['backup_hashes_valid'] = True
        self.assertTrue(evaluate.successful(report))


if __name__ == '__main__':
    unittest.main()
