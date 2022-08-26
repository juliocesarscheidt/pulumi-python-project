FROM python:3.7-slim

WORKDIR /usr/src/app

# installing tools
RUN apt-get update -y && \
    apt-get install -y \
    curl unzip less python3-pip python3-venv
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# optional - install aws cli from local file
# COPY sources/awscli.zip .
# instead, this would install using the external source file
RUN curl --silent \
  -L https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
  -o awscli.zip
RUN unzip awscli.zip && \
    ./aws/install -i /usr/local/aws-cli -b /usr/local/bin
RUN rm -rf awscli.zip && \
    rm -rf aws/

# install pulumi from local file
# COPY sources/pulumi.tar.gz .
# instead, this would install using the external source file
RUN curl --silent \
    -L https://get.pulumi.com/releases/sdk/pulumi--version3.38.0-linux-x64.tar.gz \
    -o pulumi.tar.gz
RUN tar -xzvf pulumi.tar.gz && \
    mv pulumi/* /usr/local/bin/
RUN rm -rf pulumi.tar.gz && \
    rm -rf pulumi/

RUN groupadd pulumi && \
    useradd \
    --gid pulumi --shell /bin/sh \
    --create-home --home-dir /home/pulumi pulumi
# optional - change new user's password
RUN echo "pulumi:pulumi" | chpasswd

# copy requirements to install
COPY requirements.txt .

# change current workdir owner to pulumi user
RUN chown -R pulumi:pulumi .
# change user to pulumi
USER pulumi

RUN python3 -m venv venv

RUN venv/bin/python3 -m pip install \
    --upgrade pip setuptools wheel
RUN venv/bin/python3 -m pip install \
    --requirement requirements.txt

VOLUME ["/usr/src/app/venv"]

ENTRYPOINT []
CMD ["/bin/sh"]
