# Build the application binary
ARG GOLANG_IMAGE
FROM ${GOLANG_IMAGE} as builder
WORKDIR /work

COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-w -s" -o devcontainer-example server.go

# Build the application image
FROM gcr.io/distroless/static:nonroot
LABEL org.opencontainers.image.source https://github.com/idcf-private/cloud-voyager-addons/devcontainer-example

COPY --chown=nonroot:nonroot --from=builder /work/devcontainer-example /devcontainer-example
ENTRYPOINT ["/devcontainer-example"]
