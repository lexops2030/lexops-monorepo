# ── Stage 1: Build ──
FROM node:20-alpine AS builder
WORKDIR /app

# تفعيل pnpm
RUN corepack enable && corepack prepare pnpm@9.1.0 --activate

# نسخ ملفات الإعدادات فقط أولاً
COPY package.json ./

# تثبيت المكتبات (بدون الحاجة لملف القفل)
RUN pnpm install --no-frozen-lockfile

# نسخ باقي ملفات المشروع (الكود)
COPY . .

# بناء المشروع (تحويل كود TypeScript إلى JavaScript في مجلد dist)
RUN pnpm run build

# ── Stage 2: Production ──
FROM node:20-alpine
WORKDIR /app

# نسخ الملفات الجاهزة فقط من مرحلة البناء لتقليل حجم الحاوية
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

# فتح المنفذ الذي يطلبه Cloud Run
EXPOSE 8080

# تشغيل التطبيق
CMD ["node", "dist/main"]
