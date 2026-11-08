import importlib.util
import datetime as dt
import json
from pathlib import Path
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location('memory', Path(__file__).resolve().parents[2] / 'tools/ai/memory.py')
memory = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(memory)


class MemoryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def write(self, name, text):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding='utf-8')
        return path

    def test_fts_accents_changes_and_deletion(self):
        path = self.write('docs/memory/one.md', '# Decisión\nReproducción Linux')
        self.assertEqual(len(memory.search(self.root, 'reproduccion')), 1)
        path.write_text('Android nuevo', encoding='utf-8')
        self.assertEqual(memory.search(self.root, 'reproduccion'), [])
        self.assertEqual(len(memory.search(self.root, 'Android')), 1)
        path.unlink()
        self.assertEqual(memory.search(self.root, 'Android'), [])

    def test_obsolete_excluded(self):
        self.write('docs/memory/old.md', 'Estado: obsoleta\nLinux')
        self.assertEqual(memory.search(self.root, 'Linux'), [])
        self.assertEqual(len(memory.search(self.root, 'Linux', include_obsolete=True)), 1)

    def test_symlinks_and_scope(self):
        self.write('private.md', 'secreto')
        self.write('docs/memory/real.md', 'visible')
        (self.root / 'docs/memory/link.md').symlink_to(self.root / 'private.md')
        self.assertEqual(memory.search(self.root, 'secreto'), [])
        (self.root / '.ai-local').mkdir(exist_ok=True)
        (self.root / '.ai-local/memory.sqlite3').unlink()
        (self.root / '.ai-local/memory.sqlite3').symlink_to(self.root / 'private.md')
        with self.assertRaises(ValueError):
            memory.index(self.root)

    def test_lint_conflicts_and_links(self):
        header = 'Fuente: diseño\nFecha: 2026-01-01\nMódulo: player\nEstado: vigente\nDecisión: motor\nEvidencia: pruebas\n'
        self.write('docs/memory/a.md', header + 'Claim: motor = A\n[mal](../../../escape.md)')
        self.write('docs/memory/b.md', header + 'Claim: motor = B')
        self.write('docs/memory/README.md', 'índice')
        issues = memory.check(self.root)
        self.assertTrue(any('incompatible' in issue['issue'] for issue in issues))
        self.assertTrue(any('Enlace' in issue['issue'] for issue in issues))
        self.assertFalse(any('Falta' in issue['issue'] for issue in issues))

    def test_budget_and_deterministic_handoff(self):
        self.write('docs/memory/current.md', 'Estado: vigente\n' + 'Linux ' * 1000)
        result = memory.handoff(self.root, 256)
        self.assertTrue(result)
        self.assertLessEqual(len(json.dumps(result, ensure_ascii=False)), 256)
        self.assertEqual(result, memory.handoff(self.root, 256))
        result = memory.search(self.root, 'Linux', max_chars=512)
        self.assertLessEqual(len(json.dumps(result, ensure_ascii=False)), 512)

    def test_missing_future_and_research(self):
        self.write('docs/memory/research.md',
                   'Tipo: investigación\nFecha: 9999-01-01\nEstado: vigente\nClaim: motor = B')
        self.write('docs/memory/decision.md',
                   'Estado: vigente\nClaim: motor = A')
        issues = memory.check(self.root)
        self.assertTrue(any('Falta metadata' in row['issue'] for row in issues))
        self.assertTrue(any('Fecha futura' in row['issue'] for row in issues))
        self.assertTrue(any('Investigación' in row['issue'] for row in issues))
        self.assertFalse(any('incompatible' in row['issue'] for row in issues))

    def test_handoff_shares_budget_between_state_and_next_task(self):
        self.write('docs/memory/ARCHITECTURE_INDEX.md', 'Arquitectura ' * 1000)
        self.write('docs/memory/PROJECT_STATE.md', 'Estado actual: listo\n' + 'avance ' * 1000)
        self.write('docs/memory/AI_HANDOFF.md', 'Siguiente tarea: validar\n' + 'pasos ' * 1000)
        result = memory.handoff(self.root, 1000)
        self.assertEqual([Path(row['path']).stem for row in result[:2]],
                         ['PROJECT_STATE', 'AI_HANDOFF'])
        self.assertIn('Estado actual', result[0]['excerpt'])
        self.assertIn('Siguiente tarea', result[1]['excerpt'])
        self.assertTrue(result[0]['truncated'])
        self.assertLessEqual(len(json.dumps(result, ensure_ascii=False)), 1000)

    def test_explicit_reference_date(self):
        self.write('docs/memory/date.md', 'Fecha: 2026-11-08')
        self.assertTrue(any(row['issue'] == 'Fecha futura'
                            for row in memory.check(self.root, dt.date(2026, 11, 7))))
        self.assertFalse(any(row['issue'] == 'Fecha futura'
                             for row in memory.check(self.root, dt.date(2026, 11, 8))))

    def test_document_size_limit_is_explicit(self):
        self.write('docs/memory/oversized.md', 'x' * (256 * 1024 + 1))
        with self.assertRaisesRegex(ValueError, 'Documento excede límite de 262144 bytes'):
            memory.index(self.root)

    def test_corpus_size_limit_is_explicit(self):
        for number in range(17):
            self.write(f'docs/memory/{number}.md', 'x' * (256 * 1024))
        with self.assertRaisesRegex(ValueError, 'Corpus excede límite de 4194304 bytes'):
            memory.index(self.root)

    def test_document_count_limit_is_explicit(self):
        for number in range(501):
            self.write(f'docs/memory/{number}.md', 'small')
        with self.assertRaisesRegex(ValueError, 'Corpus excede límite de 500 documentos'):
            memory.index(self.root)

    def test_handoff_large_source_is_bounded_and_marked(self):
        self.write('docs/memory/PROJECT_STATE.md', '# Estado\n' + 'estado ' * 20000)
        self.write('docs/memory/AI_HANDOFF.md', '# Siguiente\n' + 'tarea ' * 20000)
        result = memory.handoff(self.root, 1000)
        self.assertEqual(len(result), 2)
        self.assertTrue(all(row['truncated'] for row in result))
        self.assertLessEqual(len(json.dumps(result, ensure_ascii=False)), 1000)

    def test_handoff_thirty_docs_retains_late_actionable_sections(self):
        header = 'Fuente: local\nFecha: 2026-11-07\nMódulo: memoria\nEstado: vigente\nDecisión: continuar\nEvidencia: prueba\nTipo: decisión\n'
        padding = ''.join(f'\n## Contexto {index}\n' + 'información ' * 100 for index in range(16))
        self.write('docs/memory/PROJECT_STATE.md', header + padding + '\n## Objetivo\nCompletar cerebro portable concreto\n')
        self.write('docs/memory/AI_HANDOFF.md', header + padding + '\n## Siguiente tarea\nValidar restauración en equipo nuevo\n')
        for number in range(28):
            self.write(f'docs/memory/other{number:02}.md', header + '# Contexto\n' + 'detalle ' * 500)
        result = memory.handoff(self.root, 6000)
        self.assertLessEqual(len(result), 6)
        state = next(row for row in result if row['path'].endswith('PROJECT_STATE.md'))
        handoff = next(row for row in result if row['path'].endswith('AI_HANDOFF.md'))
        self.assertIn('Completar cerebro portable concreto', state['excerpt'])
        self.assertIn('Validar restauración en equipo nuevo', handoff['excerpt'])
        self.assertNotIn('Fuente: local', state['excerpt'])
        self.assertLessEqual(len(json.dumps(result, ensure_ascii=False)), 6000)


if __name__ == '__main__':
    unittest.main()
