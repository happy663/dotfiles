import importlib.util
import json
import os
import subprocess
import tempfile
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

sys.dont_write_bytecode = True

spec = importlib.util.spec_from_file_location('changelog', Path(__file__).with_name('neovim-changelog.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ChangelogTest(unittest.TestCase):
    def test_configuration_excludes_tests_and_lockfile(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            base = root / 'conf/.config/nvim'
            (base / 'tests').mkdir(parents=True)
            (base / 'init.lua').write_text('vim.o.number = true')
            (base / 'lazy-lock.json').write_text('LOCKFILE_CONTENT')
            (base / 'tests/test.lua').write_text('TEST_CONTENT')
            text = module.configuration(root)
            self.assertIn('1: vim.o.number = true', text)
            self.assertIn('tests/test.lua', text)
            self.assertNotIn('TEST_CONTENT', text)
            self.assertNotIn('LOCKFILE_CONTENT', text)

    def test_failure_status_is_visible(self):
        with tempfile.TemporaryDirectory() as folder:
            out = Path(folder)
            module.status(out, 'OPENCODE_API_KEY Secret 未設定')
            self.assertIn('Secret 未設定', module.render(out, False))

    def test_pi_failure_reasons_without_api_calls(self):
        script = Path(__file__).with_name('explain-neovim-changelog.sh').resolve()
        for scenario, expected in [('secret', 'Secret 未設定'), ('install', 'インストール失敗'),
                                   ('model', 'モデル解決失敗'), ('timeout', 'タイムアウト'),
                                   ('empty', '出力が空'), ('success', None)]:
            with self.subTest(scenario=scenario), tempfile.TemporaryDirectory() as folder:
                root = Path(folder)
                (root / 'ci-logs').mkdir()
                (root / 'ci-logs/neovim-input.md').write_text('test input')
                (root / 'bin').mkdir()
                pi = root / 'neovim-pi/node_modules/.bin/pi'
                pi.parent.mkdir(parents=True)
                pi.write_text('#!/bin/sh\n[ "$SCENARIO" = model ] && exit 1\necho "opencode-go deepseek-v4.1-flash"\n')
                pi.chmod(0o755)
                for name, body in {
                    'npm': '[ "$SCENARIO" != install ]',
                    'timeout': '[ "$SCENARIO" = timeout ] && exit 124\n[ "$SCENARIO" = empty ] || echo explanation',
                }.items():
                    command = root / 'bin' / name
                    command.write_text('#!/bin/sh\n' + body + '\n')
                    command.chmod(0o755)
                env = dict(os.environ, RUNNER_TEMP=folder, SCENARIO=scenario,
                           OPENCODE_API_KEY='' if scenario == 'secret' else 'stub-key',
                           PATH=str(root / 'bin') + os.pathsep + os.environ['PATH'])
                result = subprocess.run(['bash', str(script)], cwd=root, env=env, capture_output=True, text=True)
                if expected:
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn(expected, (root / 'ci-logs/neovim-status.txt').read_text())
                    self.assertFalse((root / 'ci-logs/neovim-ai.md').exists())
                else:
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual((root / 'ci-logs/neovim-ai.md').read_text().strip(), 'explanation')

    def test_paginated_json(self):
        self.assertEqual(module.json_pages(' {"commits": []}\n {"commits": [1]}\n'),
                         [{"commits": []}, {"commits": [1]}])

    def test_news_sections_and_empty_old_file(self):
        old = 'BREAKING CHANGES                         *news-breaking*\nEDITOR\nold\nNEW FEATURES                            *news-features*\nOPTIONS\n'
        new = old.replace('old\n', 'old\n• block motion changed\n').replace('OPTIONS\n', 'OPTIONS\n• pathopt\n')
        result = module.news_diff(old, new)
        self.assertIn('BREAKING CHANGES / EDITOR', result)
        self.assertIn('NEW FEATURES / OPTIONS', result)
        self.assertIn('- pathopt', result)
        self.assertIn('- pathopt', module.news_diff('', new))

    def test_reset_and_oversized_news(self):
        self.assertIn('リセット', module.news_diff('old\n' * 10, 'new\n'))
        self.assertIn('300 行を超え', module.news_diff('', '\n'.join(str(i) for i in range(301))))

    def test_failed_collection_retains_fallback(self):
        with tempfile.TemporaryDirectory() as folder:
            out = Path(folder)
            with patch.object(module, 'gh', side_effect=subprocess.CalledProcessError(1, 'gh')):
                module.collect('a' * 40, 'b' * 40, out, out)
            self.assertIn('取得できません', module.render(out, False))
            self.assertIn('/compare/', module.render(out, False))

    def test_collect_commits_with_redirected_links(self):
        import json
        commit = {'sha': 'c' * 40, 'commit': {'message': 'fix(ui): example (#42)'}}
        with tempfile.TemporaryDirectory() as folder:
            out = Path(folder)
            with patch.object(module, 'gh', side_effect=['', '', json.dumps({'commits': [commit], 'total_commits': 1})]):
                module.collect('a' * 40, 'b' * 40, out, out)
            source = out.joinpath('neovim-source.md').read_text()
            self.assertIn('total commits: 1', source)
            self.assertIn('redirect.github.com/neovim/neovim/pull/42', source)
            self.assertTrue(out.joinpath('neovim-input.md').exists())

    def test_ai_failure_oversize_and_link_rewrite(self):
        with tempfile.TemporaryDirectory() as folder:
            out = Path(folder)
            out.joinpath('neovim-source.md').write_text('evidence')
            ai = out.joinpath('neovim-ai.md')
            ai.write_text('partial output')
            self.assertNotIn('partial output', module.render(out, False))
            ai.write_text('x' * (module.AI_LIMIT + 1))
            self.assertIn('生成できません', module.render(out, True))
            ai.write_text('https://github.com/neovim/neovim/pull/123')
            self.assertIn('https://redirect.github.com/neovim/neovim/pull/123', module.render(out, True))

    def test_unchanged_does_not_request_ai(self):
        with tempfile.TemporaryDirectory() as folder:
            out = Path(folder)
            module.collect('a' * 40, 'a' * 40, out, out)
            self.assertFalse(out.joinpath('neovim-input.md').exists())
            self.assertNotIn('生成できません', module.render(out, False))


if __name__ == '__main__':
    unittest.main()
