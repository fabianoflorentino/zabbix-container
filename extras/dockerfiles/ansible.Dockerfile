FROM python:3.7-alpine

COPY requirements.txt .

RUN apk add vim make sshpass openssh gcc g++ libffi-dev openssl openssl-dev \
  && adduser --disabled-password --gecos "" ansible \
  && pip install -r requirements.txt

USER ansible

WORKDIR /ansible

ENTRYPOINT [ "sh" ]