# 兴安盟 AVC 仿真器镜像 — ems_simulate 后端（含 3 处本地补丁：point_manager/slave_manager/slave_service）
# c104 / pydnp3-pure 为 git 依赖（容器内 GitHub 不可达），由宿主机预编译进 wheels/ 安装；
# 其余依赖走清华 PyPI 镜像。
FROM python:3.12 AS builder

ENV PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple \
    PIP_DEFAULT_TIMEOUT=120

WORKDIR /build
COPY wheels/ wheels/
COPY requirements-docker.txt ./

RUN python -m venv /app/.venv \
 && /app/.venv/bin/pip install --no-cache-dir --no-index --find-links=wheels "c104==2.2.2" "pydnp3-pure" \
 && /app/.venv/bin/pip install --no-cache-dir -r requirements-docker.txt

COPY . /app/
WORKDIR /app
RUN /app/.venv/bin/pip install --no-cache-dir --no-deps .

FROM python:3.12-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends libatomic1 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app /app
ENV PATH="/app/.venv/bin:$PATH"

EXPOSE 8991 502 2404
HEALTHCHECK --interval=30s --timeout=5s --start-period=25s --retries=3 \
  CMD python -c "import urllib.request;urllib.request.urlopen('http://127.0.0.1:8991/api/health',timeout=3)" || exit 1

CMD ["python", "start_back_end.py"]
