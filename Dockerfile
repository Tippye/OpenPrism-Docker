FROM node:22-bookworm

RUN rm -f /etc/apt/sources.list.d/debian.sources && \
    echo "deb http://mirrors.tuna.tsinghua.edu.cn/debian bookworm main contrib non-free non-free-firmware" > /etc/apt/sources.list && \
    echo "deb http://mirrors.tuna.tsinghua.edu.cn/debian bookworm-updates main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list

# 安装 TeX Live Full 和中文字体支持（根据README推荐）
RUN apt-get update && apt-get install -y \
    texlive-full \
    texlive-lang-chinese \
    texlive-lang-japanese \
    texlive-lang-korean \
    fonts-noto-cjk \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 首先复制 package 文件以利用 Docker 缓存层
COPY package*.json ./
COPY apps/frontend/package*.json ./apps/frontend/
COPY apps/backend/package*.json ./apps/backend/

# 安装 Node 依赖
RUN npm install

# 复制项目源代码
COPY . .

# 构建生产环境（npm run build 会构建前后端）
RUN npm run build

# 创建数据存储目录
RUN mkdir -p /app/data/projects /app/data/templates

# 设置环境变量
ENV NODE_ENV=production
ENV PORT=8787
ENV OPENPRISM_DATA_DIR=/app/data
ENV OPENPRISM_COLLAB_REQUIRE_TOKEN=true
ENV OPENPRISM_COLLAB_TOKEN_TTL=86400

# 暴露后端服务端口
EXPOSE 8787

# 设置数据卷（用于持久化项目数据）
VOLUME ["/app/data"]

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8787/health || exit 1

# 启动命令（生产模式）
CMD ["npm", "run", "dev"]

