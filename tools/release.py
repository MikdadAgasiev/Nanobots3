"""Bounded, resumable release of the exact allowlisted mod snapshot.

No credentials, private plans, or test saves belong in this repository.
"""
from __future__ import annotations

import argparse
from contextlib import contextmanager
import base64
import hashlib
import importlib.metadata
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import sys
import tempfile
import time
from urllib.parse import urlparse
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED, BadZipFile

ROOT = Path(__file__).resolve().parents[1]
PROFILE = json.loads((ROOT / "tools/release-project.json").read_text(encoding="utf8"))
MOD = PROFILE["mod"]
REPO = PROFILE["repository"]
if not re.fullmatch(r"[A-Za-z0-9_-]+", MOD) or REPO != "MikdadAgasiev/" + MOD:
    raise RuntimeError("Unexpected release project")
DATA = Path(os.environ.get("LOCALAPPDATA", str(Path.home() / ".local/share"))) / "FactorioRelease" / "projects" / MOD
PRIVATE = DATA / "config.json"
PUBLIC = (".gitignore", "release.ps1", "tools/release.py", "tools/secrets_store.py", "tools/setup_access.py",
          "tools/package-files.json", "tools/release-project.json", "tools/README.md", "tools/tests/test_release.py", ".github/workflows/quick-checks.yml")


class ReleaseError(Exception):
    pass


def digest(data):
    return hashlib.sha256(data).hexdigest()


def load(path, default=None):
    return json.loads(path.read_text(encoding="utf-8-sig")) if path.exists() else default


def save(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf8")
    os.replace(tmp, path)


@contextmanager
def release_lock():
    DATA.mkdir(parents=True, exist_ok=True)
    with (DATA / "release.lock").open("a+b") as f:
        if f.tell() == 0:
            f.write(b"0")
            f.flush()
        f.seek(0)
        try:
            if os.name == "nt":
                import msvcrt
                msvcrt.locking(f.fileno(), msvcrt.LK_NBLCK, 1)
            else:
                import fcntl
                fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            raise ReleaseError("Another release command is already running") from None
        yield


def files(root=ROOT):
    names = load(root / "tools/package-files.json")
    if not names or len(names) != len(set(names)):
        raise ReleaseError("Invalid package allowlist")
    result = {}
    for name in names:
        part = PurePosixPath(name)
        if part.is_absolute() or ".." in part.parts or "\\" in name:
            raise ReleaseError("Unsafe package path")
        path = root / name
        if not path.is_file() or path.is_symlink() or not path.resolve().is_relative_to(root.resolve()):
            raise ReleaseError("Missing or linked package file: " + name)
        result[name] = path.read_bytes()
    # A new production module must never silently disappear from the ZIP.
    if {p.name for p in root.glob("*.lua")} - set(result):
        raise ReleaseError("New Lua modules need an explicit package allowlist entry")
    info = json.loads(result["info.json"])
    if info["name"] != MOD or not re.fullmatch(r"\d+\.\d+\.\d+", info["version"]):
        raise ReleaseError("Unexpected mod name or version")
    for name in result:
        if any(x.casefold() in {"agents.md", "rules.md", "factorio_mechanics.md", ".env"} for x in PurePosixPath(name).parts):
            raise ReleaseError("Private file in package")
    return result, info


def fingerprint(values):
    return digest(json.dumps({k: digest(v) for k, v in sorted(values.items())}, sort_keys=True).encode())


def zip_matches(path, values, version):
    try:
        with ZipFile(path) as z:
            prefix = f"{MOD}_{version}/"
            return (len(z.namelist()) == len(values) and
                    set(z.namelist()) == {prefix + n for n in values} and
                    all(z.read(prefix + n) == b for n, b in values.items()))
    except (OSError, ValueError, BadZipFile):
        return False


def package(out, values, version):
    path = out / f"{MOD}_{version}.zip"
    out.mkdir(parents=True, exist_ok=True)
    if path.exists():
        if not zip_matches(path, values, version):
            raise ReleaseError("Existing version has different bytes; increment info.json version")
        return path
    temporary = path.with_suffix(".zip.tmp")
    with ZipFile(temporary, "w", compression=ZIP_DEFLATED) as z:
        for name, data in sorted(values.items()):
            entry = ZipInfo(f"{MOD}_{version}/{name}", date_time=(2020, 1, 1, 0, 0, 0))
            entry.compress_type = ZIP_DEFLATED
            entry.external_attr = 0o100644 << 16
            z.writestr(entry, data)
    if not zip_matches(temporary, values, version):
        raise ReleaseError("Built archive does not match its source")
    os.replace(temporary, path)
    return path


def syntax(values):
    try:
        from lupa.lua52 import LuaRuntime
        compile_lua = LuaRuntime().eval("function(s,n)local f,e=load(s,n);assert(f,e)end")
        for name, data in values.items():
            if name.endswith(".lua"):
                compile_lua(data.decode("utf-8-sig"), name)
    except ImportError as e:
        raise ReleaseError('Lua 5.2 parser missing; install Python package "lupa"') from e


def graphify_pass(reviews, sha):
    # Only the real bot, this exact commit, and an explicit gate verdict count.
    matching = [r for r in reviews if r.get("user", {}).get("login") == "graphify-labs[bot]"
                and r.get("commit_id") == sha and r.get("state") in {"COMMENTED", "APPROVED"}]
    if not matching:
        return False
    body = sorted(matching, key=lambda r: r.get("submitted_at", ""))[-1].get("body", "")
    return bool(re.search(r"## graphify gate\s+\*\*PASS\*\*", body)
                and not re.search(r"\*\*(FAIL|BLOCKED)\*\*", body))


def manual_review_pass(review, snapshot):
    # Explicit, local, exact-snapshot attestation; never inferred from a timeout.
    return (review.get("snapshot") == snapshot and review.get("outcome") == "PASS"
            and review.get("reason") == "Graphify monthly quota exhausted"
            and review.get("reviewer") == "Codex" and bool(review.get("notes")))


class Runner:
    def __init__(self, root=ROOT, seconds=900):
        self.root = root
        self.deadline = time.monotonic() + seconds
        self.config = load(PRIVATE, {})
        self.values, self.info = files(root)
        self.source = fingerprint(self.values)
        self.public_values = {n: (root / n).read_bytes() for n in PUBLIC if (root / n).is_file()}
        self.snapshot = fingerprint({**self.values, **self.public_values})
        self.work = DATA / "runs" / (self.info["version"] + "-" + self.snapshot[:16])
        self.work.mkdir(parents=True, exist_ok=True)
        self.receipt = self.work / "receipt.json"
        self.state = load(self.receipt, {"source": self.source})
        if self.state.get("source") != self.source:
            raise ReleaseError("Stale release receipt")

    def remaining(self):
        value = self.deadline - time.monotonic()
        if value <= 0:
            raise ReleaseError("Time budget reached; rerun to resume. Nothing is marked passed on timeout.")
        return value

    def record(self, **items):
        self.state.update(items)
        save(self.receipt, self.state)

    def assert_snapshot(self):
        current = {n: (self.root / n).read_bytes() for n in PUBLIC if (self.root / n).is_file()}
        if fingerprint(files(self.root)[0]) != self.source or current != self.public_values:
            raise ReleaseError("Files changed during release; rerun on the new snapshot")

    def command(self, args, label, limit=180):
        logfile = self.work / (label + ".log")
        env = os.environ.copy()
        env["PYTHONUTF8"] = "1"
        startup = None
        if os.name == "nt":
            startup = subprocess.STARTUPINFO()
            startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
            startup.wShowWindow = 0
        with logfile.open("wb") as stream:
            timeout = min(limit, self.remaining())
            try:
                r = subprocess.Popen(args, cwd=self.root, env=env, stdout=stream, stderr=subprocess.STDOUT,
                                     startupinfo=startup, start_new_session=os.name != "nt")
                r.wait(timeout=timeout)
            except subprocess.TimeoutExpired as e:
                if os.name == "nt":
                    subprocess.run(["taskkill", "/PID", str(r.pid), "/T", "/F"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                else:
                    import signal
                    os.killpg(r.pid, signal.SIGKILL)
                r.wait()
                raise ReleaseError(label + " timed out; see " + str(logfile)) from e
        if r.returncode:
            raise ReleaseError(label + " failed; see " + str(logfile))
        return logfile

    def check(self, native=False):
        self.assert_snapshot()
        test_files = {str(p.relative_to(self.root)): p.read_bytes() for p in (self.root / "tools").rglob("*.py")}
        commands = self.config.get("targeted_commands", [])
        for command in commands:
            for item in command:
                test_path = Path(item) if Path(item).is_absolute() else self.root / item
                if item.endswith(".py") and test_path.is_file():
                    test_files["external-test/" + item] = test_path.read_bytes()
        environment = {"python": sys.version, "platform": sys.platform}
        for dependency in ("lupa", "requests"):
            try:
                environment[dependency] = importlib.metadata.version(dependency)
            except importlib.metadata.PackageNotFoundError:
                environment[dependency] = "missing"
        key = digest((fingerprint({**self.values, **test_files}) + json.dumps(commands) + json.dumps(environment, sort_keys=True)).encode())
        cache = DATA / "cache" / (key + ".json")
        if load(cache, {}).get("quick") is not True:
            print("Quick checks: Lua 5.2 and release regressions", flush=True)
            syntax(self.values)
            self.command([sys.executable, "-m", "unittest", "discover", "-s", "tools/tests", "-v"], "unit")
            for i, command in enumerate(commands):
                self.command(command, "targeted-" + str(i))
            save(cache, {"quick": True, "fingerprint": key})
        else:
            print("Quick checks: unchanged source, cached PASS", flush=True)
        out = Path(self.config.get("output", str(self.root.parent / "releases")))
        self.archive = package(out, self.values, self.info["version"])
        self.record(archive=str(self.archive), sha256=digest(self.archive.read_bytes()), quick=True)
        if native:
            self.native_check()
        self.assert_snapshot()
        return self.archive

    def native_check(self):
        engine = Path(self.config.get("engine", ""))
        fixture = Path(self.config.get("fixture", ""))
        if not engine.is_file() or not (fixture / "mods/mod-list.json").is_file() or not (fixture / "source-save.zip").is_file():
            raise ReleaseError("Configure engine and isolated fixture in " + str(PRIVATE))
        env = {"engine": digest(engine.read_bytes()), "fixture": digest((fixture / "source-save.zip").read_bytes()),
               "mods": sorted((p.name, p.stat().st_size, p.stat().st_mtime_ns) for p in (fixture / "mods").iterdir()),
               "listing": digest((fixture / "mods/mod-list.json").read_bytes())}
        # Descriptions/changelog do not invalidate a game-code check.
        code = {k: v for k, v in self.values.items() if k.endswith(".lua") or k == "info.json"}
        key = digest((fingerprint(code) + json.dumps(env, sort_keys=True) + "native-v1").encode())
        cache = DATA / "cache" / (key + ".json")
        if load(cache, {}).get("native") is True:
            print("Factorio: unchanged code/environment, cached PASS", flush=True)
            return
        print("Factorio: one bounded packaged-ZIP startup", flush=True)
        stage = Path(tempfile.mkdtemp(prefix="game-", dir=self.work))
        def clone(src, dest):
            if Path(src).suffix == ".zip":
                try:
                    os.link(src, dest)
                    return dest
                except OSError:
                    pass
            return shutil.copy2(src, dest)
        shutil.copytree(fixture / "mods", stage / "mods",
                        ignore=shutil.ignore_patterns(MOD, MOD + "_*.zip"), copy_function=clone)
        shutil.copy2(self.archive, stage / "mods" / self.archive.name)
        config = stage / "config.ini"
        config.write_text(f"[path]\nread-data={engine.parents[2].as_posix()}/data\nwrite-data={stage.as_posix()}\n[other]\ncheck-updates=false\n", encoding="utf8")
        log = self.command([str(engine), "--config", str(config), "--mod-directory", str(stage / "mods"),
                            "--benchmark", str(fixture / "source-save.zip"), "--benchmark-ticks", "120"], "native", 180)
        text = log.read_text(encoding="utf8", errors="replace")
        if f"Loading mod {MOD} {self.info['version']}" not in text or "Performed 120 updates" not in text or "Error while running" in text:
            raise ReleaseError("Native startup did not pass: " + str(log))
        save(cache, {"native": True, "fingerprint": key})

    def api(self, method, url, key=None, missing=False, **kwargs):
        import requests
        parsed = urlparse(url)
        if parsed.scheme != "https" or parsed.hostname not in {"api.github.com", "uploads.github.com", "mods.factorio.com"}:
            raise ReleaseError("Unexpected API destination")
        headers = {"Accept": "application/vnd.github+json"} if "github.com" in parsed.hostname else {}
        headers.update(kwargs.pop("headers", {}))
        if key:
            headers["Authorization"] = "Bearer " + key
        try:
            response = requests.request(method, url, headers=headers, timeout=(5, min(25, self.remaining())),
                                        allow_redirects=False, **kwargs)
        except requests.RequestException as e:
            raise ReleaseError("API interrupted; rerun to reconcile remote state before retrying") from None
        if missing and response.status_code == 404:
            return None
        if response.status_code >= 300:
            raise ReleaseError(f"API HTTP {response.status_code}: {parsed.hostname}{parsed.path}")
        return response.json() if response.content else {}

    def gh(self, method, path, **kwargs):
        return self.api(method, f"https://api.github.com/repos/{REPO}" + ("/" + path if path else ""), self.github_key, **kwargs)

    def publish_source(self):
        self.assert_snapshot()
        print("GitHub: reconcile exact source snapshot", flush=True)
        values = dict(self.values)
        if set(self.public_values) != set(PUBLIC):
            raise ReleaseError("Missing release tooling file")
        values.update(self.public_values)
        branch = "release/" + self.info["version"] + "-" + fingerprint(values)[:10]
        base = self.gh("GET", "git/ref/heads/main")["object"]["sha"]
        commit = self.gh("GET", "git/commits/" + base)
        tree = self.gh("GET", "git/trees/" + commit["tree"]["sha"] + "?recursive=1")
        if tree.get("truncated"):
            raise ReleaseError("Truncated GitHub tree")
        blobs = {e["path"]: e["sha"] for e in tree["tree"] if e["type"] == "blob"}
        changed = {n: data for n, data in values.items() if blobs.get(n) != hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()}
        removed = [n for n in blobs if "/" not in n and n.endswith(".lua") and n not in values]
        if not changed and not removed:
            self.record(github_commit=base)
            return base
        ref = self.gh("GET", "git/ref/heads/" + branch, missing=True)
        if not ref:
            entries = []
            for name, data in changed.items():
                blob = self.gh("POST", "git/blobs", json={"content": base64.b64encode(data).decode(), "encoding": "base64"})
                entries.append({"path": name, "mode": "100644", "type": "blob", "sha": blob["sha"]})
            entries.extend({"path": name, "mode": "100644", "type": "blob", "sha": None} for name in removed)
            tree_sha = commit["tree"]["sha"]
            for start in range(0, len(entries), 100):
                tree_sha = self.gh("POST", "git/trees", json={"base_tree": tree_sha, "tree": entries[start:start + 100]})["sha"]
            head = self.gh("POST", "git/commits", json={"message": "Release " + self.info["version"], "tree": tree_sha, "parents": [base]})["sha"]
            self.gh("POST", "git/refs", json={"ref": "refs/heads/" + branch, "sha": head})
        else:
            head = ref["object"]["sha"]
            current = self.gh("GET", "git/trees/" + self.gh("GET", "git/commits/" + head)["tree"]["sha"] + "?recursive=1")
            indexed = {e["path"]: e["sha"] for e in current["tree"]}
            if any(n in indexed for n in removed) or any(indexed.get(n) != hashlib.sha1(b"blob " + str(len(d)).encode() + b"\0" + d).hexdigest() for n, d in values.items()):
                raise ReleaseError("Existing release branch differs; will not force-push")
        prs = self.gh("GET", "pulls", params={"state": "open", "head": REPO.split('/')[0] + ":" + branch})
        title = "Release " + self.info["version"] if any(n in self.values for n in changed) else "Automate release checks and publication"
        pr = prs[0] if prs else self.gh("POST", "pulls", json={"title": title, "head": branch, "base": "main", "body": "Automated exact-snapshot release. Quick checks and isolated packaged-ZIP startup passed. Internal rules and private fixtures are excluded."})
        self.record(pr=pr["number"], review_head=head)
        print(f"GitHub: PR #{pr['number']}; waiting for exact-commit Graphify review (bounded, no chat polling)", flush=True)
        while True:
            reviews = self.gh("GET", f"pulls/{pr['number']}/reviews?per_page=100")
            if graphify_pass(reviews, head):
                self.record(review="Graphify PASS", review_head=head)
                break
            manual = load(DATA / "reviews" / (self.snapshot + ".json"), {})
            if manual_review_pass(manual, self.snapshot):
                self.record(review="Manual review: Graphify monthly quota exhausted", review_head=head)
                break
            self.remaining()
            time.sleep(min(15, self.remaining()))
        # CI may still be running; never merge a failed required quick check.
        while True:
            checks = self.gh("GET", "actions/runs", params={"per_page": 100})
            runs = [r for r in checks.get("workflow_runs", []) if r.get("head_sha") == head]
            required = [r for r in runs if r.get("name") == "Quick checks"]
            if required:
                latest = max(required, key=lambda r: (r.get("run_number", 0), r.get("run_attempt", 1)))
                if latest.get("status") == "completed":
                    if latest.get("conclusion") != "success":
                        raise ReleaseError("Required Quick checks did not succeed; release stopped")
                    break
            time.sleep(min(10, self.remaining()))
        self.assert_snapshot()
        try:
            merged = self.gh("PUT", f"pulls/{pr['number']}/merge", json={"sha": head, "merge_method": "merge"})
            if not merged.get("merged"):
                raise ReleaseError("Merge was not confirmed")
        except ReleaseError:
            # A timed-out merge can already have advanced main; reconcile before any retry.
            current = self.gh("GET", "git/ref/heads/main")["object"]["sha"]
            parents = self.gh("GET", "git/commits/" + current).get("parents", [])
            if not any(p["sha"] == head for p in parents):
                raise
            merged = {"sha": current}
        self.record(github_commit=merged["sha"])
        final_tree = self.gh("GET", "git/trees/" + self.gh("GET", "git/commits/" + merged["sha"])["tree"]["sha"] + "?recursive=1")
        indexed = {e["path"]: e["sha"] for e in final_tree["tree"]}
        if final_tree.get("truncated") or any(n in indexed for n in removed) or any(indexed.get(n) != hashlib.sha1(b"blob " + str(len(d)).encode() + b"\0" + d).hexdigest() for n, d in values.items()):
            raise ReleaseError("Merged main differs from the checked snapshot; portal publication stopped")
        return merged["sha"]

    def publish_portal(self):
        self.assert_snapshot()
        print("Factorio portal: reconcile published version and checksum", flush=True)
        base = "https://mods.factorio.com"
        details = self.api("GET", f"{base}/api/mods/{MOD}/full")
        existing = next((r for r in details["releases"] if r["version"] == self.info["version"]), None)
        expected = hashlib.sha1(self.archive.read_bytes()).hexdigest()
        if existing and existing["sha1"] != expected:
            raise ReleaseError("Portal version exists with different archive; will not overwrite")
        if not existing:
            upload = self.api("POST", base + "/api/v2/mods/releases/init_upload", self.portal_key, data={"mod": MOD})
            url = upload.get("upload_url", "")
            if urlparse(url).scheme != "https" or not urlparse(url).hostname:
                raise ReleaseError("Invalid portal upload URL")
            import requests
            # No bearer credential is forwarded to the upload/CDN destination.
            with self.archive.open("rb") as f:
                try:
                    result = requests.post(url, files={"file": (self.archive.name, f, "application/zip")}, timeout=(5, min(60, self.remaining())), allow_redirects=False)
                    if result.status_code >= 300 or not result.json().get("success"):
                        raise ReleaseError("Portal upload not confirmed; rerun to reconcile")
                except requests.RequestException:
                    raise ReleaseError("Upload interrupted; rerun to reconcile") from None
        faq = Path(self.config.get("faq", ""))
        fields = {"mod": MOD, "title": self.info["title"], "summary": self.info["description"],
                  "description": Path(self.config.get("description", str(self.root / "README.md"))).read_text(encoding="utf8"),
                  "license": PROFILE.get("license", "default_mit"), "source_url": "https://github.com/" + REPO}
        if faq.is_file():
            fields["faq"] = faq.read_text(encoding="utf8")
        feedback = "\n\n## Feedback\n\nWe welcome bug reports, questions and suggestions! Please use [GitHub Issues](https://github.com/" + REPO + "/issues) and include your versions, plan or blueprint, and steps to reproduce the problem.\n"
        if "We welcome bug reports" not in fields["description"]:
            fields["description"] += feedback
        if re.search(r"[А-Яа-яЁё]", fields["description"] + fields.get("faq", "")):
            raise ReleaseError("Portal description and FAQ must be English; no local rules may be uploaded")
        result = self.api("POST", base + "/api/v2/mods/edit_details", self.portal_key, data=fields)
        if result.get("success") is not True:
            raise ReleaseError("Portal metadata update not confirmed")
        actual = self.api("GET", f"{base}/api/mods/{MOD}/full")
        if not any(r["version"] == self.info["version"] and r["sha1"] == expected for r in actual["releases"]):
            raise ReleaseError("Published archive verification failed")
        self.record(portal_sha1=expected)

    def github_archive(self, commit):
        print("GitHub: reconcile versioned release asset", flush=True)
        tag = "v" + self.info["version"]
        item = self.gh("GET", "releases/tags/" + tag, missing=True)
        if not item:
            preview = PROFILE.get("prerelease", False)
            item = self.gh("POST", "releases", json={"tag_name": tag, "target_commitish": commit,
                            "name": self.info["version"] + (" (In Development)" if preview else ""), "prerelease": preview,
                            "body": "Verify generated layouts or changed behavior in a sandbox. Bug reports, questions and suggestions are welcome in GitHub Issues."})
        asset = next((a for a in item.get("assets", []) if a["name"] == self.archive.name), None)
        expected = "sha256:" + digest(self.archive.read_bytes())
        if asset and asset.get("digest") != expected:
            raise ReleaseError("GitHub release asset differs or has no checksum; will not overwrite")
        if not asset:
            url = item["upload_url"].split("{", 1)[0]
            with self.archive.open("rb") as f:
                asset = self.api("POST", url, self.github_key, params={"name": self.archive.name},
                                 headers={"Content-Type": "application/zip"}, data=f)
            if asset.get("digest") != expected:
                raise ReleaseError("GitHub asset checksum was not confirmed")
        self.record(github_release=item["html_url"])

    def install(self):
        mods = Path(self.config.get("mods", str(Path(os.environ.get("APPDATA", "")) / "Factorio/mods")))
        if not (mods / "mod-list.json").is_file():
            raise ReleaseError("Configured Factorio mods folder is invalid")
        entries = load(mods / "mod-list.json")["mods"]
        enabled = next((e for e in entries if e["name"] == MOD), {})
        if not enabled.get("enabled") or enabled.get("version") not in (None, self.info["version"]):
            raise ReleaseError("Mod disabled or pinned to another version; installation cannot activate it")
        target = mods / self.archive.name
        if target.exists() and target.read_bytes() != self.archive.read_bytes():
            raise ReleaseError("Installed version differs; will not replace silently")
        if not target.exists():
            shutil.copy2(self.archive, target)
        self.record(installed_sha256=digest(target.read_bytes()))

    def publish(self):
        if os.name != "nt":
            raise ReleaseError("Publication uses Windows DPAPI; quick checks remain cross-platform")
        from secrets_store import read_secret
        self.github_key = read_secret("github")
        self.portal_key = read_secret("factorio")
        if not self.github_key or not self.portal_key:
            raise ReleaseError("Release access not configured; run python tools/setup_access.py")
        # Validate both accesses before creating a remote release branch.
        self.gh("GET", "")
        portal = "https://mods.factorio.com/api/v2/mods/"
        self.api("POST", portal + "releases/init_upload", self.portal_key, data={"mod": MOD})
        permission = self.api("POST", portal + "edit_details", self.portal_key, data={"mod": MOD})
        if permission.get("success") is not True:
            raise ReleaseError("Factorio Edit Mods access was not confirmed")
        self.check(native=True)
        commit = self.publish_source()
        self.publish_portal()
        self.github_archive(commit)
        self.install()
        self.record(complete=True)
        print(json.dumps({"complete": True, "version": self.info["version"], "github_commit": commit,
                          "archive": str(self.archive), "receipt": str(self.receipt)}, ensure_ascii=False))


def run_cli(args):
    r = Runner(seconds=args.budget)
    if args.mode == "publish":
        r.publish()
    elif args.mode == "check":
        r.check(native=args.native)
        print("PASS; receipt: " + str(r.receipt))
    elif args.mode == "full":
        command = r.config.get("full_command")
        if not command:
            raise ReleaseError("Full tests require an explicit local full_command; they are never started by publish")
        r.command(command, "full", limit=args.budget)
    else:
        print(json.dumps(r.state, ensure_ascii=False, indent=2))


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("mode", choices=["check", "publish", "status", "full"], nargs="?", default="check")
    p.add_argument("--native", action="store_true")
    p.add_argument("--budget", type=int, default=900)
    args = p.parse_args()
    if not 1 <= args.budget <= (21600 if args.mode == "full" else 900):
        p.error("Ordinary runs are limited to 900 seconds; explicit full runs to 21600 seconds")
    try:
        with release_lock():
            run_cli(args)
        return 0
    except (ReleaseError, OSError, ValueError) as e:
        print("STOP: " + str(e), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
