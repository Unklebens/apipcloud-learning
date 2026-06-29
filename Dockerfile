FROM alpine:3
RUN apk add --no-cache bash curl jq util-linux
# util-linux c'est pour uuidgen
COPY *.sh /
RUN chmod +x /compare.sh main.sh
ENTRYPOINT ["/compare.sh"]