FROM ubuntu:15.04

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install kubuntu-desktop curl -y
