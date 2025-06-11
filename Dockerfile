FROM jenkins/jenkins:lts

USER root

ARG DOCKER_GID=992

# RUN apt-get update && apt-get install -y git docker.io \
#     && groupmod -g ${DOCKER_GID} docker || groupadd -g ${DOCKER_GID} docker \
#     && usermod -aG docker jenkins

# Docker ve git kurulumu
RUN apt-get update && apt-get install -y git docker.io unzip wget \
    && groupmod -g ${DOCKER_GID} docker || groupadd -g ${DOCKER_GID} docker \
    && usermod -aG docker jenkins

# Terraform kurulumu
RUN wget https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip && \
    unzip terraform_1.6.6_linux_amd64.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform_1.6.6_linux_amd64.zip

RUN apt-get update && \
    apt-get install -y ansible


RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws




COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

 # Ansible ve AWS Python SDK modülleri
RUN pip install boto3 botocore

# community.aws koleksiyonunu yükle
RUN ansible-galaxy collection install community.aws

COPY casc_configs/ /var/jenkins_home/casc_configs/
COPY init.groovy.d/ /var/jenkins_home/init.groovy.d/

ENV CASC_JENKINS_CONFIG=/var/jenkins_home/casc_configs/jenkins.yaml
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

USER jenkins





