FROM debian:jessie

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install kde-standard -y

CMD [ "/bin/bash" ]
