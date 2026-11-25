"""EMS Simulate - 电力模拟仿真系统"""

from importlib.metadata import PackageNotFoundError, version

try:
    __version__ = version("ems_simulate")
except PackageNotFoundError:
    # 开发模式下未安装包，从 pyproject.toml 读取
    try:
        from pathlib import Path
        import tomllib

        _pyproject = Path(__file__).resolve().parent.parent / "pyproject.toml"
        with _pyproject.open("rb") as f:
            __version__ = tomllib.load(f)["project"]["version"]
    except Exception:
        __version__ = "0.0.0"

# 本地补丁⑦：冻结模式（PyInstaller）下读 exe 同级 version.txt（交付包由 make-package 写入，
# 本地 dist 由 rebuild_onedir 写入），修复冻结丢包元数据导致版本恒为 0.0.0 的问题。
import sys as _sys

if getattr(_sys, "frozen", False):
    try:
        from pathlib import Path as _Path

        _vt = _Path(_sys.executable).resolve().parent / "version.txt"
        if _vt.is_file():
            _v = _vt.read_text(encoding="utf-8").strip()
            if _v:
                __version__ = _v
    except Exception:
        pass
