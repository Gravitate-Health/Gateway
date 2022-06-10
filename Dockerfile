FROM node:12-alpine

RUN apk --update --no-cache add busybox-extras curl

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 4444 9876 8080

CMD [ "node", "server.js" ]
