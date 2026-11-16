import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
from zipfile import ZipFile

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))
import release


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "tools/tests").mkdir(parents=True)
        self.values = {"info.json": json.dumps({"name": release.MOD, "version": "1.0.0"}).encode(),
                       "control.lua": b"return 1\n", "README.md": b"English description\n"}
        for n, data in self.values.items():
            (self.root / n).write_bytes(data)
        (self.root / "tools/package-files.json").write_text(json.dumps(list(self.values)))

    def tearDown(self):
        self.tmp.cleanup()

    def test_package_is_exact_deterministic_and_excludes_private_files(self):
        (self.root / "AGENTS.md").write_text("private rules")
        (self.root / ".env").write_text("not a real secret")
        first = release.package(self.root / "out", self.values, "1.0.0")
        second = release.package(self.root / "other", self.values, "1.0.0")
        self.assertEqual(first.read_bytes(), second.read_bytes())
        self.assertTrue(release.zip_matches(first, self.values, "1.0.0"))
        with ZipFile(first) as z:
            self.assertEqual(len(z.namelist()), 3)
            self.assertFalse(any("AGENTS" in n or ".env" in n for n in z.namelist()))

    def test_published_version_never_overwritten(self):
        path = release.package(self.root / "out", self.values, "1.0.0")
        original = path.read_bytes()
        changed = dict(self.values, **{"control.lua": b"return 2"})
        with self.assertRaises(release.ReleaseError):
            release.package(self.root / "out", changed, "1.0.0")
        self.assertEqual(path.read_bytes(), original)

    def test_reuse_preserves_original_checked_zip_bytes(self):
        path = self.root / "out" / f"{release.MOD}_1.0.0.zip"
        path.parent.mkdir()
        with ZipFile(path, "w") as z:
            for n, data in self.values.items():
                z.writestr(f"{release.MOD}_1.0.0/" + n, data)
        before = path.read_bytes()
        self.assertEqual(release.package(path.parent, self.values, "1.0.0").read_bytes(), before)

    def test_allowlist_rejects_traversal_and_private_rules(self):
        for bad in ("../outside", "/absolute", "folder\\file", "AGENTS.md"):
            (self.root / "AGENTS.md").write_text("private")
            (self.root / "tools/package-files.json").write_text(json.dumps(list(self.values) + [bad]))
            with self.assertRaises(release.ReleaseError):
                release.files(self.root)

    def test_new_module_cannot_be_silently_omitted(self):
        (self.root / "new.lua").write_text("return 3")
        with self.assertRaises(release.ReleaseError):
            release.files(self.root)

    def test_syntax_checks_real_lua_52(self):
        release.syntax(self.values)
        with self.assertRaises(Exception):
            release.syntax({"broken.lua": b"local = nope"})

    def test_fingerprint_changes_on_bytes_and_paths(self):
        self.assertNotEqual(release.fingerprint({"a": b"same"}), release.fingerprint({"b": b"same"}))
        self.assertNotEqual(release.fingerprint({"a": b"same"}), release.fingerprint({"a": b"different"}))

    def test_cache_reuses_only_same_source_and_test_code(self):
        with patch.object(release, "DATA", self.root / "private"), patch.object(release, "PRIVATE", self.root / "no-config"), patch.object(release.Runner, "command") as command:
            r = release.Runner(root=self.root)
            r.config = {"output": str(self.root / "out")}
            r.check()
            self.assertEqual(command.call_count, 1)
            r.check()
            self.assertEqual(command.call_count, 1)
            (self.root / "tools/test_helper.py").write_text("# changed regression")
            r.check()
            self.assertEqual(command.call_count, 2)

    def test_graphify_accepts_only_explicit_gate_for_exact_commit(self):
        good = {"user": {"login": "graphify-labs[bot]"}, "commit_id": "abc", "state": "COMMENTED",
                "body": "<!-- graphify-inline:abc -->\n**No blocking issues.**\n## graphify gate\n**PASS** — objectively clean"}
        self.assertTrue(release.graphify_pass([good], "abc"))
        for update in ({"commit_id": "old"}, {"user": {"login": "someone"}},
                       {"state": "DISMISSED"}, {"body": "PASS"},
                       {"body": good["body"] + "\n**FAIL**"}, {"state": "CHANGES_REQUESTED"}):
            self.assertFalse(release.graphify_pass([{**good, **update}], "abc"), update)

    def test_timeout_never_counts_as_pass(self):
        with patch.object(release, "DATA", self.root / "private"), patch.object(release, "PRIVATE", self.root / "no-config"):
            r = release.Runner(root=self.root)
            r.deadline = 0
            with self.assertRaises(release.ReleaseError):
                r.remaining()
            self.assertNotIn("complete", r.state)

    def test_edit_during_release_stops_snapshot(self):
        with patch.object(release, "DATA", self.root / "private"), patch.object(release, "PRIVATE", self.root / "no-config"):
            r = release.Runner(root=self.root)
            (self.root / "control.lua").write_text("return 100")
            with self.assertRaises(release.ReleaseError):
                r.assert_snapshot()

    def test_repeated_install_preserves_files_and_rejects_pin(self):
        mods = self.root / "mods"
        mods.mkdir()
        listing = {"mods": [{"name": release.MOD, "enabled": True}]}
        (mods / "mod-list.json").write_text(json.dumps(listing))
        with patch.object(release, "DATA", self.root / "private"), patch.object(release, "PRIVATE", self.root / "no-config"):
            r = release.Runner(root=self.root)
            r.config = {"mods": str(mods)}
            r.archive = release.package(self.root / "out", self.values, "1.0.0")
            r.install()
            target = mods / r.archive.name
            stamp = target.stat().st_mtime_ns
            r.install()
            self.assertEqual(stamp, target.stat().st_mtime_ns)
            listing["mods"][0]["version"] = "0.1.0"
            (mods / "mod-list.json").write_text(json.dumps(listing))
            with self.assertRaises(release.ReleaseError):
                r.install()

    def test_failed_publication_never_claims_complete(self):
        with patch.object(release, "DATA", self.root / "private"), patch.object(release, "PRIVATE", self.root / "no-config"), patch.dict(sys.modules, {"secrets_store": unittest.mock.Mock(read_secret=lambda _: "dummy")}), patch.object(release.Runner, "api", side_effect=release.ReleaseError("API unavailable")):
            r = release.Runner(root=self.root)
            with self.assertRaises(release.ReleaseError):
                r.publish()
            self.assertNotIn("complete", r.state)

    def test_native_failure_never_enters_cache(self):
        with patch.object(release, "DATA", self.root / "private"), patch.object(release, "PRIVATE", self.root / "no-config"):
            r = release.Runner(root=self.root)
            r.config = {"output": str(self.root / "out")}
            with self.assertRaises(release.ReleaseError):
                r.check(native=True)
            self.assertFalse(any(load.get("native") for load in (json.loads(p.read_text()) for p in (self.root / "private/cache").glob("*.json"))))

    def test_api_refuses_credential_redirect_destination(self):
        with patch.object(release, "DATA", self.root / "private"), patch.object(release, "PRIVATE", self.root / "no-config"):
            r = release.Runner(root=self.root)
            for url in ("http://api.github.com/foo", "https://evil.invalid/token", "https://api.github.com.evil.invalid/foo"):
                with self.assertRaises(release.ReleaseError):
                    r.api("POST", url, "dummy-not-a-real-token")


if __name__ == "__main__":
    unittest.main()
