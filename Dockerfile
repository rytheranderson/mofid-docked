# 3.10 is the highest version that works with the setup.py out of the box
FROM python:3.12-slim-bullseye

# Install dependencies
RUN apt-get -qq update
# Prevents default-jre installation from crashing
RUN mkdir -p /usr/share/man/man1/
RUN apt-get install -qq default-jre
RUN apt-get install -qq build-essential cmake

# Copy over the source
WORKDIR /mofid
COPY . /mofid

# Compile openbabel, C++ analysis code, and python scripts
RUN make init
RUN python set_paths.py
RUN pip install .
