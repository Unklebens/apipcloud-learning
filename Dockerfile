FROM alpine:3
RUN apk add --no-cache bash curl jq 
COPY *.sh /
RUN chmod +x /entrypoint.sh 
ENTRYPOINT ["/entrypoint.sh"]