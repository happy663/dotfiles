import importlib.util
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
