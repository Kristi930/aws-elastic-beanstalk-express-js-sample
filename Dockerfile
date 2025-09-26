FROM node:16-alpine

WORKDIR /app

COPY package*.json ./

RUN npm ci --only=production || npm install --only=production

COPY . .

EXPOSE 8080

CMD ["node", "app.js"]
