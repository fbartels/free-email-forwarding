# there is already node:13-alpine but https://github.com/forwardemail/free-email-forwarding/blob/master/.travis.yml only tests up to version 12
FROM node:12-alpine

ENV NODE_ENV production
EXPOSE 25

RUN apk add --no-cache \
  python3 \
  spamassassin \
  spamassassin-client \
  openssl

# forward-email is looking for python at the wrong location
RUN ln -s /usr/bin/python3 /usr/bin/python

RUN pip3 install --no-cache-dir dkimpy pyspf dnspython

# TODO it does not feel like a good idea to generate this here
RUN \
  openssl genrsa -out dkim-private.key 1024 && \
  openssl rsa -in dkim-private.key -pubout -out dkim-public.key && \
  echo "Add this to your DNS zonefile:" && \
  sed '3,3!d' dkim-public.key | sed ':a;N;$!ba;s/\n//g' | xargs -I{} echo "default._domainkey 14400 IN TXT \"v=DKIM1; k=rsa; p={}\"" | tee DKIM-TXT-record

WORKDIR /app
COPY package.json yarn.lock /app/
RUN yarn
COPY * /app/

ENV \
  IP_ADDRESS="" \
  EXCHANGES="" \
  SECURE="false" \
  SSL_KEY="" \
  SSL_KEY=FILE="" \
  SSL_CERT="" \
  SSL_CERT_FILE="" \
  SSL_CA="" \
  SSL_CA_FILE="" \
  DKIM_PRIVATE_KEY="" \
  DKIM_KEY_SELECTOR="default" \
  DKIM_PRIVATE_KEY_FILE=/app/dkim-private.key

CMD ["node", "index.js"]

