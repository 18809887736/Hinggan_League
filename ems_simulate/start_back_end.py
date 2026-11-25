"""EMS Simulate 后端入口 - FastAPI 应用

用法:
    python start_back_end.py
    python start_back_end.py --port 8991
    python start_back_end.py --port 8991 --root-dir ./data

Tauri 侧通过 Rust spawn 传入 --port 和 EMS_ROOT_DIR 环境变量。
stdout/stderr 由 Rust 侧 Stdio::null() 统一抑制，Python 层无需处理。
"""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import sys
import time


def _parse_args() -> argparse.Namespace:
    """解析命令行参数（Tauri sidecar / direct spawn 传入 --port）"""
    parser = argparse.ArgumentParser(description="EMS Simulate Backend")
    parser.add_argument("--port", type=int, default=None, help="服务端口号（缺省时读取 config.ini）")
    parser.add_argument("--root-dir", type=str, default=None, help="数据根目录（优先级低于 EMS_ROOT_DIR 环境变量）")
    return parser.parse_args()


def _get_root_dir(cli_root: str | None) -> Path:
    """Resolve the runtime data root before importing the FastAPI app."""
    if env_root := os.environ.get("EMS_ROOT_DIR"):
        return Path(env_root)
    if cli_root:
        return Path(cli_root)
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent
    return Path(__file__).resolve().parent


def _bundled_path(name: str) -> Path:
    if getattr(sys, "frozen", False) and hasattr(sys, "_MEIPASS"):
        return Path(sys._MEIPASS) / name
    return Path(__file__).resolve().parent / name


def _prepare_runtime_root(root_dir: Path) -> None:
    root_dir.mkdir(parents=True, exist_ok=True)
    for sub in ("data", "log", "config", "upload", "plan"):
        (root_dir / sub).mkdir(parents=True, exist_ok=True)
    (root_dir / "data" / "point_csv").mkdir(parents=True, exist_ok=True)

    config_target = root_dir / "config.ini"
    # Web 包的配置与可执行文件同级；桌面 sidecar 仍可使用内置初始配置。
    config_source = (
        Path(sys.executable).resolve().parent / "config.ini"
        if getattr(sys, "frozen", False)
        else _bundled_path("config.ini")
    )
    if not config_source.is_file():
        config_source = _bundled_path("config.ini")
    if not config_target.exists() and config_source.exists():
        config_target.write_bytes(config_source.read_bytes())

    # 首次运行时复制初始数据库
    db_target = root_dir / "data" / "ems.db"
    if not db_target.exists() or db_target.stat().st_size == 0:
        db_source = _bundled_path("data/ems.db")
        if db_source.is_file() and db_source.stat().st_size > 0:
            # Replace atomically so an interrupted first launch cannot leave a
            # partial SQLite file that then survives every later restart.
            db_temp = db_target.with_suffix(".db.tmp")
            db_temp.write_bytes(db_source.read_bytes())
            db_temp.replace(db_target)

    # 首次运行时复制样本点表文件
    point_csv_target = root_dir / "data" / "point_csv"
    point_csv_source = _bundled_path("data/point_csv")
    if point_csv_source.is_dir() and not any(point_csv_target.iterdir()):
        for f in point_csv_source.iterdir():
            if f.is_file():
                (point_csv_target / f.name).write_bytes(f.read_bytes())


def _activate_runtime_config(root_dir: Path):
    """Pin all late imports to one runtime root and load its editable config."""
    resolved_root = root_dir.expanduser().resolve(strict=False)
    os.environ["EMS_ROOT_DIR"] = str(resolved_root)

    from src.config.config import Config, resolve_config_path

    Config.load_config(str(resolve_config_path(resolved_root)))
    return Config


def _open_browser_when_ready(host: str, port: int, timeout_s: float = 60.0) -> None:
    """本地补丁⑤：等服务真正可访问后用默认浏览器打开 Web 页面（open_browser=true 时）。"""
    import threading
    import urllib.request
    import webbrowser

    browser_host = host if host not in ("", "0.0.0.0", "::") else "127.0.0.1"
    url = f"http://{browser_host}:{port}/"

    def _wait_and_open() -> None:
        deadline = time.monotonic() + timeout_s
        while time.monotonic() < deadline:
            try:
                with urllib.request.urlopen(f"{url}api/health", timeout=2):
                    pass
                break
            except OSError:
                time.sleep(0.5)
        else:
            print(f"[open_browser] {timeout_s}s 内服务未就绪，放弃打开浏览器")
            return
        time.sleep(0.5)  # 让静态资源挂载与首轮路由初始化完成
        if not webbrowser.open(url):
            print(f"[open_browser] 无法调起默认浏览器，请手动访问 {url}")

    threading.Thread(target=_wait_and_open, name="open-browser", daemon=True).start()


def _acquire_single_instance_lock(root_dir: Path):
    """本地补丁⑥：同一运行根只允许一个实例（Windows 命名互斥体 / Linux 抽象域套接字）。

    锁按运行根区分：同一部署双击两次会被拦截；不同 EMS_ROOT_DIR（不同端口/库）
    的并行调试实例不受影响。互斥体随进程退出自动释放，崩溃无残留锁。
    """
    import hashlib

    digest = hashlib.sha256(str(root_dir).lower().encode("utf-8")).hexdigest()[:16]
    if sys.platform == "win32":
        import ctypes

        ERROR_ALREADY_EXISTS = 183
        kernel32 = ctypes.windll.kernel32  # type: ignore[attr-defined]
        handle = kernel32.CreateMutexW(None, False, f"Local\\EMS_Simulate_Backend_{digest}")
        if not handle:
            return None  # 创建失败时保守放行，不因锁功能阻断启动
        if kernel32.GetLastError() == ERROR_ALREADY_EXISTS:
            kernel32.CloseHandle(handle)
            print(f"[single-instance] 运行根已有实例在运行：{root_dir}，本次启动退出")
            sys.exit(0)
        return handle
    try:
        import errno
        import socket

        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.bind(f"\0ems_simulate_backend_{digest}")
        return s
    except OSError as e:
        if getattr(e, "errno", None) == errno.EADDRINUSE:
            print(f"[single-instance] 运行根已有实例在运行：{root_dir}，本次启动退出")
            sys.exit(0)
        return None  # 环境不支持抽象套接字时保守放行


if __name__ == "__main__":
    args = _parse_args()
    root_dir = _get_root_dir(args.root_dir).expanduser().resolve(strict=False)
    _single_instance_lock = _acquire_single_instance_lock(root_dir)
    _prepare_runtime_root(root_dir)
    Config = _activate_runtime_config(root_dir)

    # Late imports keep CLI parsing and runtime root setup deterministic.
    from fastapi.responses import HTMLResponse
    from fastapi.staticfiles import StaticFiles
    import uvicorn

    from src import __version__ as backend_version
    from src.web.app import app

    # 挂载静态文件（前端打包产物）
    static_dir = (
        Path(sys._MEIPASS) / "www"
        if getattr(sys, "frozen", False) and hasattr(sys, "_MEIPASS")
        else Path(__file__).resolve().parent / "www"
    )

    # 本地补丁⑦：首页注入版本号徽标（右下角小字，免前端重编译；须在 StaticFiles 挂载前注册）
    # 本地补丁⑧：同一路由顺带注入 CSS 隐藏上游页脚版权栏（Copyright © 2026 CDY，App.vue .app-footer）
    @app.get("/", include_in_schema=False)
    async def _index_with_version() -> HTMLResponse:
        html = (static_dir / "index.html").read_text(encoding="utf-8")
        inject = (
            "<style>.app-footer{display:none!important}</style>"
            '<div style="position:fixed;right:14px;bottom:12px;z-index:9999;'
            "font-size:12px;color:#8a94a6;opacity:.85;user-select:none;"
            'font-family:Consolas,monospace;pointer-events:none;">'
            f"v{backend_version}</div>"
        )
        if "</body>" in html:
            html = html.replace("</body>", inject + "</body>", 1)
        return HTMLResponse(html)

    app.mount("/", StaticFiles(directory=str(static_dir), html=True), name="static")

    effective_port = args.port if args.port is not None else Config.web_port
    if Config.open_browser:
        _open_browser_when_ready(Config.web_host, effective_port)

    uvicorn.run(
        "src.web.app:app",
        host=Config.web_host,
        port=effective_port,
        log_level="info",
        reload=False,
        # Uvicorn 0.40 creates its own loop, bypassing event-loop policies.
        # aiomqtt needs add_reader/add_writer, unavailable on Windows Proactor.
        loop="asyncio:SelectorEventLoop" if sys.platform == "win32" else "auto",
    )
