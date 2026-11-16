"""Windows user-bound DPAPI storage. Never prints stored credentials."""
import ctypes
from ctypes import wintypes
import os
import tempfile
from pathlib import Path


class Blob(ctypes.Structure):
    _fields_ = [("size", wintypes.DWORD), ("data", ctypes.POINTER(ctypes.c_char))]


def crypt(data, decrypt=False):
    if os.name != "nt":
        raise OSError("Credential setup requires Windows")
    buffer = ctypes.create_string_buffer(data)
    source = Blob(len(data), ctypes.cast(buffer, ctypes.POINTER(ctypes.c_char)))
    target = Blob()
    dll = ctypes.WinDLL("crypt32", use_last_error=True)
    function = dll.CryptUnprotectData if decrypt else dll.CryptProtectData
    function.argtypes = [ctypes.POINTER(Blob), ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p,
                         ctypes.c_void_p, wintypes.DWORD, ctypes.POINTER(Blob)]
    function.restype = wintypes.BOOL
    if not function(ctypes.byref(source), None, None, None, None, 1, ctypes.byref(target)):
        raise ctypes.WinError(ctypes.get_last_error())
    try:
        return ctypes.string_at(target.data, target.size)
    finally:
        ctypes.memset(target.data, 0, target.size)
        free = ctypes.windll.kernel32.LocalFree
        free.argtypes = [ctypes.c_void_p]
        free.restype = ctypes.c_void_p
        free(ctypes.cast(target.data, ctypes.c_void_p))


def secret_path(name):
    if name not in {"github", "factorio"}:
        raise ValueError("Unknown credential")
    return Path(os.environ["LOCALAPPDATA"]) / "FactorioRelease/secrets" / (name + ".bin")


def write_secret(name, text):
    path = secret_path(name)
    path.parent.mkdir(parents=True, exist_ok=True)
    encrypted = crypt(text.encode("utf8"))
    handle, temporary = tempfile.mkstemp(dir=path.parent, suffix=".tmp")
    try:
        with os.fdopen(handle, "wb") as stream:
            stream.write(encrypted)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def read_secret(name):
    path = secret_path(name)
    return crypt(path.read_bytes(), decrypt=True).decode("utf8") if path.exists() else None
