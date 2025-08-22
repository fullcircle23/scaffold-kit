FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json* pnpm-lock.yaml* yarn.lock* ./
RUN npm ci || yarn install --frozen-lockfile || pnpm install --frozen-lockfile
COPY . .
RUN npm run build || yarn build || pnpm build
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx","-g","daemon off;"]
