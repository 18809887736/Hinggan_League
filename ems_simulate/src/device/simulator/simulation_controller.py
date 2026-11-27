import math
import threading
import zlib

from src.device.simulator.log import log
from src.device.simulator.point_simulator import PointSimulator
from src.enums.point_data import SimulateMethod, Yc, Yt, Yx
from src.enums.points.change_tracker import ChangeSource, track_change

# 本地补丁9（r2）：窄带宽判定阈值（max - min）。宽限值（±1e9 / ±2.1e9 原样）视为「未配带宽」。
# 与 sim_config/band-check-20261127.sql 第③段阈值保持一致。
BAND_MAX_WIDTH = 1000.0
# 本地补丁9（r3）：窄带宽点的正弦周期逐点取 40~89 s（上游恒为 60 s）。
BAND_CYCLE_MIN_S = 40.0
BAND_CYCLE_SPAN_S = 50


def _stable_hash(code, salt: str) -> int:
    """本地补丁9（r3）：点码加盐的 CRC32，跨进程稳定（不受 PYTHONHASHSEED 影响）。"""
    return zlib.crc32(f"{salt}:{code}".encode())


def _stable_phase(code) -> float:
    """本地补丁9（r3）：点码 → [0, 2π) 内的固定相位。"""
    return (_stable_hash(code, "phase") % 3600) * math.pi / 1800.0


def _stable_cycle(code) -> float:
    """本地补丁9（r3）：点码 → 40~89 s 的固定正弦周期。"""
    return BAND_CYCLE_MIN_S + _stable_hash(code, "cycle") % int(BAND_CYCLE_SPAN_S)


class SimulationController:
    def __init__(self, device):
        self.points: dict[Yc | Yx, PointSimulator] = {}
        self.device = device
        self._simulation_thread = None  # 单线程控制
        self._stop_event = threading.Event()  # 线程停止信号
        # IEC61850 重建设备时模型尚未加载，按测点身份暂存待恢复的设置。
        self._pending_configuration: dict[tuple, dict] = {}

    def add_point(self, point: Yc | Yx, simulate_method: SimulateMethod, step: float, *, is_running: bool = False):
        # IEC61850 标准元数据 DA（品质 q、时标 t、描述 dU）不参与模拟
        from src.enums.modbus_def import ProtocolType

        if self.device.protocol_type in (ProtocolType.Iec61850Server,):
            addr = str(point.hex_address)
            if addr.endswith(".q") or addr.endswith(".t") or addr.endswith(".dU"):
                return
        # 本地补丁9（r2）：出厂默认 (Random, 参与) 一律改按库带宽推导——
        #   窄带宽遥测（见 _is_band_point）：正弦参与，且建点即置带宽中心（内存值；
        #     协议层由 push_band_initial_values 在 initProtocol 末尾推送）；
        #   其余（遥信/遥控/遥调/宽限值遥测）：不参与。
        # 5 处调用点（device.py:484/632/1215、point_operator.py:588/658）统一传 (Random, 1, True)，
        # 在此单点覆盖即等价于改全部调用点；只覆盖出厂默认，显式传入其它方式的调用不受影响。
        # 「模拟配置」对话框 / apply-simulation-config 不经过此处；设备重建时随后的
        # _restore_point_configuration 仍会恢复内存中的手动配置。
        band_point = False
        if simulate_method == SimulateMethod.Random and is_running:
            if self._is_band_point(point):
                simulate_method = SimulateMethod.SineWave
                band_point = True
                point.set_real_value((point.min_value_limit + point.max_value_limit) / 2)
            else:
                is_running = False
        simulator = PointSimulator(point, simulate_method, step)
        simulator.is_running = is_running
        # 本地补丁9（r3）：窄带宽点的相位与周期都按点码固定取值，各点起伏互相错开。
        # r2 全体同相位 0、同周期 60 s，隔离实测任意两点的相关系数 = 1.000，看起来像齐涨齐落。
        # 只错相位不够：同周期正弦的相关系数 = |cos Δφ|，随机相位下仍有约三成的点对 >0.9；
        # 周期也逐点不同（40~89 s）后，64 s 窗口内这一比例降到约一成，且随观察窗口变长继续下降。
        # 初值不受影响：建点仍置带宽中心，只有按「开始」后正弦才从各自相位起步。
        if band_point:
            simulator.phase = _stable_phase(point.code)
            simulator.cycle = _stable_cycle(point.code)
        self.points[point] = simulator
        self._restore_point_configuration(point, simulator)

    @staticmethod
    def _is_band_point(point) -> bool:
        """本地补丁9（r2）：窄带宽遥测 = Yc 且 0 < max - min <= BAND_MAX_WIDTH。"""
        return (
            isinstance(point, Yc)
            and point.min_value_limit < point.max_value_limit
            and point.max_value_limit - point.min_value_limit <= BAND_MAX_WIDTH
        )

    def push_band_initial_values(self) -> int:
        """本地补丁9（r2）：把窄带宽遥测的当前内存值推到协议层（Modbus 寄存器 / c104 点）。

        导入测点、建 c104 监视点、建 Modbus 数据区（全 0）都不读点值，内存初值不推送则
        线上仍为 0。由 Device.initProtocol / _reinit_protocol_for_iec104 在 add_points 之后调用。
        映射锁定点跳过（由映射驱动）。
        """
        # 本地补丁9（r3）：客户端设备整体不推送——客户端的可写点（如 Modbus 客户端的
        # func 3 遥测）会把初值写进远端设备；104 客户端写 Yc/Yx 则每点报一次 warning。
        from src.device.protocol.base_handler import ClientHandler

        if isinstance(getattr(self.device, "protocol_handler", None), ClientHandler):
            return 0
        pushed = 0
        for point in tuple(self.points):
            if not self._is_band_point(point) or getattr(point, "is_locked_by_mapping", False):
                continue
            try:
                slave_id = int(point.rtu_addr) if getattr(point, "rtu_addr", None) else None
                self.device.editPointData(
                    point.code,
                    point.real_value,
                    source=ChangeSource.SIMULATION,
                    detail=f"补丁9 初值 {point.code}",
                    slave_id=slave_id,
                )
                pushed += 1
            except (ValueError, SystemError) as exc:
                log.warning(f"补丁9 初值推送跳过 {point.code}: {exc}")
        if pushed:
            log.info(f"补丁9: 已推送 {pushed} 个带宽测点初值到协议层")
        return pushed

    @staticmethod
    def _configuration_key(point) -> tuple:
        return (str(point.rtu_addr), point.frame_type, point.code)

    def snapshot_configuration(self) -> dict[tuple, dict]:
        """复制模拟设置，不携带旧测点引用、线程或波形执行进度。"""
        configs = {key: dict(value) for key, value in self._pending_configuration.items()}
        for point, simulator in tuple(self.points.items()):
            config = {
                field: getattr(simulator, field)
                for field in ("simulate_method", "step", "fixed_value", "is_running", "cycle", "phase", "ramp_time")
            }
            if isinstance(point, (Yc, Yt)):
                config["min_value_limit"] = point.min_value_limit
                config["max_value_limit"] = point.max_value_limit
            configs[self._configuration_key(point)] = config
        return configs

    def restore_configuration(self, configs: dict[tuple, dict], *, defer_missing: bool = False) -> None:
        """恢复相同测点的设置；新测点保留默认值，延迟加载的模型可稍后恢复。"""
        self._pending_configuration = {key: dict(value) for key, value in configs.items()}
        for point, simulator in tuple(self.points.items()):
            self._restore_point_configuration(point, simulator)
        if not defer_missing:
            self._pending_configuration.clear()

    def _restore_point_configuration(self, point, simulator: PointSimulator) -> None:
        config = self._pending_configuration.pop(self._configuration_key(point), None)
        if config is None:
            return
        for field, value in config.items():
            if field in ("min_value_limit", "max_value_limit"):
                if isinstance(point, (Yc, Yt)):
                    setattr(point, field, value)
            else:
                setattr(simulator, field, value)

    def set_all_point_simulate_method(self, simulate_method: SimulateMethod):
        for point_simulator in self.points.values():
            point_simulator.simulate_method = simulate_method

    def apply_configuration(self, items: list[dict]) -> tuple[list[str], list[dict]]:
        """批量应用测点模拟配置（无逐点日志，避免海量日志导致卡顿）。

        配置是"要模拟的测点"的完整定义：未包含在配置中的测点停止模拟。
        返回 (成功编码列表, 失败项列表)。
        """
        configured_codes = {item.get("point_code") for item in items if item.get("point_code")}
        # 重置：未出现在配置中的测点不参与模拟
        for point, simulator in self.points.items():
            if point.code not in configured_codes:
                simulator.is_running = False
        applied: list[str] = []
        failed: list[dict] = []
        for item in items:
            point_code = item.get("point_code")
            if not point_code:
                failed.append({"point_code": point_code, "reason": "缺少 point_code"})
                continue
            simulator = next((s for p, s in self.points.items() if p.code == point_code), None)
            if simulator is None:
                failed.append({"point_code": point_code, "reason": "未找到测点"})
                continue
            try:
                if item.get("simulate_method") is not None:
                    simulator.simulate_method = SimulateMethod(item["simulate_method"])
                if item.get("step") is not None:
                    simulator.step = float(item["step"])
                if item.get("fixed_value") is not None:
                    simulator.fixed_value = float(item["fixed_value"])
                if item.get("enabled") is not None:
                    simulator.is_running = bool(item["enabled"])
                applied.append(point_code)
            except (ValueError, TypeError) as exc:
                failed.append({"point_code": point_code, "reason": str(exc)})
        return applied, failed

    def set_point_status(self, point: Yc | Yx, is_running: bool):
        if point in self.points:
            self.points[point].is_running = is_running

    def set_point_status_by_code(self, point_code: str, is_running: bool) -> bool:
        """按测点编码设置模拟启停状态"""
        for point, simulator in self.points.items():
            if point.code == point_code:
                simulator.is_running = is_running
                log.info(f"设置点 {point_code} 的模拟状态为 {'运行' if is_running else '停止'}")
                return True
        log.error(f"未找到点 {point_code}")
        return False

    def set_single_point_simulate_method(self, point_code: str, simulate_method: SimulateMethod):
        """设置单个点的模拟方法"""
        for point, simulator in self.points.items():
            if point.code == point_code:
                simulator.simulate_method = simulate_method
                log.info(f"设置点 {point_code} 的模拟方法为 {simulate_method.value}")
                return True
        log.error(f"未找到点 {point_code}")
        return False

    def set_single_point_step(self, point_code: str, step: float):
        """设置单个点的模拟步长"""
        for point, simulator in self.points.items():
            if point.code == point_code:
                simulator.step = float(step)
                log.info(f"设置点 {point_code} 的模拟步长为 {step}")
                return True
        log.error(f"未找到点 {point_code}")
        return False

    def set_single_point_fixed_value(self, point_code: str, fixed_value: float | int) -> bool:
        """设置单个点的定值模拟目标值"""
        for point, simulator in self.points.items():
            if point.code == point_code:
                simulator.fixed_value = float(fixed_value)
                log.info(f"设置点 {point_code} 的模拟定值为 {fixed_value}")
                return True
        log.error(f"未找到点 {point_code}")
        return False

    def get_point_info(self, point_code: str) -> dict | None:
        """获取单个点的信息"""
        for point, simulator in self.points.items():
            if point.code == point_code:
                info = {
                    "code": point.code,
                    "name": point.name,
                    "rtu_addr": point.rtu_addr,
                    "reg_addr": point.hex_address,
                    "func_code": point.func_code,
                    "decode_code": point.decode,
                    "value": point.real_value if isinstance(point, (Yc, Yt)) else point.value,
                    "simulate_method": simulator.simulate_method.value,
                    "step": simulator.step,
                    "fixed_value": simulator.fixed_value,
                    "is_running": simulator.is_running,
                    "frame_type": point.frame_type,
                    "iec_type_id": getattr(point, "iec_type_id", None),
                    "iec_quality": getattr(point, "iec_quality_value", 0),
                }
                # 遥测和遥调特有字段
                if isinstance(point, (Yc, Yt)):
                    info["mul_coe"] = point.mul_coe
                if isinstance(point, Yt):
                    info["add_coe"] = point.add_coe
                if isinstance(point, Yx):
                    info["bit"] = point.bit
                # 上下限值（Yc/Yt 都有）
                if isinstance(point, (Yc, Yt)):
                    info["min_value"] = point.min_value_limit
                    info["max_value"] = point.max_value_limit
                return info
        return None

    def set_point_simulation_range(self, point_code: str, min_value: float, max_value: float):
        """设置单个点的模拟范围"""
        for point, _simulator in self.points.items():
            if point.code == point_code and isinstance(point, (Yc, Yt)):
                point.min_value_limit = min_value
                point.max_value_limit = max_value
                log.info(f"设置点 {point_code} 的模拟范围为 [{min_value}, {max_value}]")
                return True
        log.error(f"未找到点 {point_code} 或该点不支持设置模拟范围")
        return False

    def start_simulation(self):
        """启动单线程模拟"""
        if not self._simulation_thread or not self._simulation_thread.is_alive():
            self._stop_event.clear()
            self._simulation_thread = threading.Thread(target=self._run_simulation, daemon=True)
            self._simulation_thread.start()

    def stop_simulation(self, timeout: float = 1.0) -> bool:
        """停止模拟线程，并返回线程是否已在超时内退出。"""
        self._stop_event.set()
        if self._simulation_thread and self._simulation_thread.is_alive():
            self._simulation_thread.join(timeout=max(0.0, timeout))
        return not self.is_simulation_running()

    def _run_simulation(self):
        """单线程模拟循环"""
        running_count = sum(1 for s in self.points.values() if s.is_running)
        log.info(f"模拟线程启动, 模拟测点个数: {running_count}")
        # 获取设备本地地址信息
        from src.enums.modbus_def import ProtocolType

        if self.device.protocol_type in (
            ProtocolType.ModbusRtu,
            ProtocolType.ModbusRtuClient,
            ProtocolType.ModbusRtuServer,
            ProtocolType.ModbusRtuOverTcp,
        ):
            local_addr = self.device.serial_port or "未知串口"
        else:
            local_addr = f"{self.device.ip}:{self.device.port}"
        while not self._stop_event.is_set():
            # IEC 61850 服务端必须按轮次批量提交。逐点调用 IedServer_update*
            # 会让每个变化都立即生成报告，订阅后很容易形成报告风暴。
            batch_writer = getattr(self.device.protocol_handler, "write_values_batch", None)
            batch_values = [] if callable(batch_writer) else None

            # 配置接口可能同时增删模拟点，使用快照避免迭代期间字典变化。
            for point_simulator in tuple(self.points.values()):
                if point_simulator.is_running and not self._stop_event.is_set():
                    point = point_simulator.point

                    # 性能优化：仅当开启追溯时才进入上下文
                    if point.change_tracking_enabled:
                        with track_change(ChangeSource.SIMULATION, f"自动模拟 {point.code}", local_addr):
                            changed = self._perform_point_simulation(
                                point_simulator,
                                write_protocol=batch_values is None,
                            )
                    else:
                        changed = self._perform_point_simulation(
                            point_simulator,
                            write_protocol=batch_values is None,
                        )

                    if batch_values is not None and changed:
                        # 与 PointOperator.edit_value 保持一致：协议层接收编码后
                        # 的 point.value，而变化判断仍使用 Yc.real_value。
                        batch_values.append((point, point.value))

            if batch_values:
                try:
                    if not batch_writer(batch_values):
                        log.warning(f"IEC61850 模拟值批量写入失败: count={len(batch_values)}")
                except Exception as e:
                    log.error(f"IEC61850 模拟值批量写入异常: count={len(batch_values)}, error={e}")

            self._stop_event.wait(1)  # 可被 stop 立即唤醒

    def _perform_point_simulation(self, point_simulator: PointSimulator, *, write_protocol: bool = True) -> bool:
        """执行单个点的模拟逻辑"""
        point = point_simulator.point
        before = point.real_value if isinstance(point, Yc) else point.value
        point_simulator.simulate()
        after = point.real_value if isinstance(point, Yc) else point.value
        changed = after != before
        if not changed or not write_protocol:
            return changed

        try:
            slave_id = int(point.rtu_addr) if hasattr(point, "rtu_addr") and point.rtu_addr else None
            if isinstance(point, Yc):
                self.device.editPointData(
                    point.code,
                    point.real_value,
                    source=ChangeSource.SIMULATION,
                    detail=f"自动模拟 {point.code}",
                    slave_id=slave_id,
                )
            else:
                self.device.editPointData(
                    point.code,
                    point.value,
                    source=ChangeSource.SIMULATION,
                    detail=f"自动模拟 {point.code}",
                    slave_id=slave_id,
                )
        except ValueError:
            # 忽略模拟超出范围异常，避免停止后续测点的模拟
            pass
        return changed

    def is_simulation_running(self) -> bool:
        """检查模拟线程是否运行"""
        return self._simulation_thread is not None and self._simulation_thread.is_alive()
