# [GLOBAL ARG]
ARG TRT_LLM_VERSION=latest

# =================================================================================================
# STAGE 1: Builder
# Description: Download Java ecosystem tools and GitHub Actions runner.
# =================================================================================================
FROM ubuntu:24.04 AS builder

# Set versions
ARG GRADLE_VERSION=9.1.0
ARG MAVEN_VERSION=3.9.11
ARG JEXTRACT_VERSION=22-6
ARG RUNNER_VERSION=2.329.0

ENV GRADLE_VERSION=${GRADLE_VERSION}
ENV MAVEN_VERSION=${MAVEN_VERSION}

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl ca-certificates tar unzip wget gnupg2 && \
    rm -rf /var/lib/apt/lists/*

# --- Download and Extract Gradle ---
ARG GRADLE_INSTALL_DIR=/opt/gradle
RUN mkdir -p ${GRADLE_INSTALL_DIR} && \
    curl -L "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-all.zip" -o /tmp/gradle.zip && \
    unzip -q /tmp/gradle.zip -d /tmp && \
    mv /tmp/gradle-${GRADLE_VERSION}/* ${GRADLE_INSTALL_DIR}/ && \
    rm -rf /tmp/gradle.zip /tmp/gradle-${GRADLE_VERSION}

# --- Download and Extract Maven ---
ARG MAVEN_INSTALL_DIR=/opt/maven
RUN mkdir -p ${MAVEN_INSTALL_DIR} && \
    curl -L "https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" -o /tmp/maven.tar.gz && \
    tar -xzf /tmp/maven.tar.gz -C /tmp && \
    mv /tmp/apache-maven-${MAVEN_VERSION}/* ${MAVEN_INSTALL_DIR}/ && \
    rm -rf /tmp/maven.tar.gz /tmp/apache-maven-${MAVEN_VERSION}

# --- Download and Extract JExtract ---
ARG JEXTRACT_INSTALL_DIR=/opt/jextract
RUN mkdir -p ${JEXTRACT_INSTALL_DIR} && \
    curl -L "https://download.java.net/java/early_access/jextract/22/6/openjdk-22-jextract+6-47_linux-x64_bin.tar.gz" -o /tmp/jextract.tar.gz && \
    tar -xzf /tmp/jextract.tar.gz -C /tmp && \
    mv /tmp/jextract-22/* ${JEXTRACT_INSTALL_DIR}/ && \
    rm -rf /tmp/jextract.tar.gz /tmp/jextract-22

# --- Download Oracle JDKs ---
RUN curl -L "https://download.oracle.com/java/25/latest/jdk-25_linux-x64_bin.deb" -o /tmp/jdk-25.deb
RUN curl -L "https://download.oracle.com/java/22/archive/jdk-22.0.2_linux-x64_bin.deb" -o /tmp/jdk-22.deb
RUN curl -L "https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.deb" -o /tmp/jdk-21.deb

# --- Download GitHub Actions Runner ---
RUN mkdir -p /tmp/actions-runner && \
    cd /tmp/actions-runner && \
    curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L \
    https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    echo "194f1e1e4bd02f80b7e9633fc546084d8d4e19f3928a324d512ea53430102e1d  actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" | sha256sum -c && \
    tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# =================================================================================================
# STAGE 2: Final Production Image
# Base: NVIDIA TensorRT-LLM Devel
# =================================================================================================
FROM nvcr.io/nvidia/tensorrt-llm/devel:${TRT_LLM_VERSION}

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# --- 1. System Tools (Removed openssh-server) ---
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    sudo nano unzip rsync locales passwd \
    git wget curl graphviz fontconfig man-db htop \
    && rm -rf /var/lib/apt/lists/*

# [FIX] Delete the marker file that blocks pip from working on system python
# This allows 'pip install virtualenv' to succeed in your build_wheel.py script
RUN rm -f /usr/lib/python3.*/EXTERNALLY-MANAGED

RUN locale-gen en_US.UTF-8

# --- 2. Install Oracle JDKs ---
COPY --from=builder /tmp/jdk-25.deb /tmp/jdk-25.deb
COPY --from=builder /tmp/jdk-22.deb /tmp/jdk-22.deb
COPY --from=builder /tmp/jdk-21.deb /tmp/jdk-21.deb
RUN dpkg -i /tmp/jdk-25.deb && \
    dpkg -i /tmp/jdk-22.deb && \
    dpkg -i /tmp/jdk-21.deb && \
    rm /tmp/jdk-*.deb

# --- 3. Install Build Tools (Maven, Gradle, JExtract) ---
COPY --from=builder /opt/gradle /opt/gradle
COPY --from=builder /opt/maven /opt/maven
COPY --from=builder /opt/jextract /opt/jextract

# --- 4. Environment Configuration ---
ENV JAVA_HOME=/usr/lib/jvm/jdk-25
ENV GRADLE_HOME=/opt/gradle
ENV MAVEN_HOME=/opt/maven
ENV JEXTRACT_HOME=/opt/jextract

ENV PATH="${JAVA_HOME}/bin:${GRADLE_HOME}/bin:${MAVEN_HOME}/bin:${JEXTRACT_HOME}/bin:${PATH}"

# --- 5. User Configuration (Keep original username 'developer') ---
RUN (userdel -r ubuntu 2>/dev/null || true) && \
    (groupdel ubuntu 2>/dev/null || true) && \
    groupadd -g 1000 developer && \
    useradd -u 1000 -g developer -m -s /bin/bash developer && \
    echo 'developer:password' | chpasswd && \
    usermod -aG sudo developer && \
    echo '%developer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# --- 6. Environment Inheritance ---
RUN echo "export PATH=${PATH}" >> /etc/profile && \
    echo "export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}" >> /etc/profile && \
    echo "export CUDA_HOME=${CUDA_HOME}" >> /etc/profile && \
    echo "export HPCX_DIR=${HPCX_DIR}" >> /etc/profile && \
    echo "export OPAL_PREFIX=${OPAL_PREFIX}" >> /etc/profile && \
    echo "export JAVA_HOME=${JAVA_HOME}" >> /etc/profile && \
    echo "export GRADLE_HOME=${GRADLE_HOME}" >> /etc/profile && \
    echo "export MAVEN_HOME=${MAVEN_HOME}" >> /etc/profile

# --- 7. Setup Developer User Environment ---
USER developer
WORKDIR /home/developer

RUN echo "export SSH_AUTH_SOCK=/ssh-agent" > ~/.bashrc_temp && \
    ([ -f ~/.bashrc ] && cat ~/.bashrc >> ~/.bashrc_temp || true) && \
    mv ~/.bashrc_temp ~/.bashrc && \
    echo "export SSH_AUTH_SOCK=/ssh-agent" >> ~/.profile && \
    touch /home/developer/.hushlogin

# --- 8. Install GitHub Actions Runner ---
USER root
RUN mkdir -p /home/developer/actions-runner && \
    chown -R developer:developer /home/developer/actions-runner

COPY --from=builder /tmp/actions-runner /home/developer/actions-runner

# Install runner dependencies
RUN cd /home/developer/actions-runner && \
    ./bin/installdependencies.sh

# Set proper ownership
RUN chown -R developer:developer /home/developer

# --- 9. Setup Working Directory ---
RUN mkdir -p /code && chown developer:developer /code

# --- 10. Entrypoint Setup ---
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER developer
WORKDIR /home/developer/actions-runner

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]