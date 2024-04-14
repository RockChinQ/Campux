FROM golang:1.22.1

WORKDIR /app

COPY bin/campux /app/campux
COPY frontend/dist /app/frontend/dist

EXPOSE 8080

ENV GIN_MODE=release

CMD ["./campux"]