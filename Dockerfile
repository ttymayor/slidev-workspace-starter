# 使用 Node.js 官方映像作為基礎
FROM node:22-alpine AS base

# 安裝 pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# 設置工作目錄
WORKDIR /app

# 複製 pnpm workspace 配置文件
COPY pnpm-workspace.yaml package.json pnpm-lock.yaml ./
COPY slidev-workspace.yaml ./

# 複製所有 slides 目錄
COPY slides ./slides

# 安裝依賴
RUN pnpm install --frozen-lockfile

# 構建階段
FROM base AS builder

WORKDIR /app

# 構建所有 slides
RUN pnpm run build

# 生產階段
FROM node:22-alpine AS runner

# 安裝 pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# 複製 package.json、lock file 和 workspace 配置以安裝 serve
COPY pnpm-workspace.yaml package.json pnpm-lock.yaml ./

# 創建空的 slides 目錄以滿足 workspace 結構要求
RUN mkdir -p slides

# 只安裝根目錄的生產依賴（包含 serve）
RUN pnpm install --prod --frozen-lockfile --filter .

# 從構建階段複製構建產物（slidev-workspace 構建到 _gh-pages 目錄）
COPY --from=builder /app/_gh-pages ./dist
COPY --from=builder /app/slidev-workspace.yaml ./

# 暴露端口（Zeabur 會通過 $PORT 環境變數指定）
EXPOSE 3000

# 啟動服務（使用環境變數 PORT，預設為 3000）
CMD sh -c "pnpm exec serve -s dist -l ${PORT:-3000}"

