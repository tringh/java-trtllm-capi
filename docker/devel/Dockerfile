# [GLOBAL ARG]
ARG TRT_LLM_VERSION=1.0.0

# =================================================================================================
# STAGE 1: Builder
# Description: Download Java ecosystem tools.
# =================================================================================================
FROM ubuntu:24.04 AS builder

# Set versions
ARG IDEA_VERSION=2025.2.4
ARG GRADLE_VERSION=9.1.0
ARG MAVEN_VERSION=3.9.11
ARG JEXTRACT_VERSION=22-6

ENV IDEA_VERSION=${IDEA_VERSION}
ENV GRADLE_VERSION=${GRADLE_VERSION}
ENV MAVEN_VERSION=${MAVEN_VERSION}

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl ca-certificates tar unzip wget gnupg2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# --- Download and Extract IntelliJ IDEA Ultimate (Remote Server Only) ---
ARG IDEA_INSTALL_DIR=/opt/jetbrains/idea
RUN mkdir -p ${IDEA_INSTALL_DIR}
RUN curl -L "https://download.jetbrains.com/idea/ideaIU-${IDEA_VERSION}.tar.gz" | \
    tar -xz -C ${IDEA_INSTALL_DIR} --strip-components=1 && \
    cd ${IDEA_INSTALL_DIR} && \
    find plugins/ -mindepth 1 -maxdepth 1 ! -name 'java' \
                                          ! -name 'java-ide-customization' \
                                          ! -name 'gradle' \
                                          ! -name 'gradle-java' \
                                          ! -name 'maven' \
                                          ! -name 'remote-dev-server' \
                                          ! -name 'git4idea' \
                                          -exec rm -rf {} + 2>/dev/null || true && \
    rm -rf jbr/lib/libjavafx*.* 2>/dev/null || true && \
    rm -rf lib/src.zip \
           lib/*.zip 2>/dev/null || true && \
    rm -rf license/ \
           Install-Linux-tar.txt \
           build.txt 2>/dev/null || true && \
    find plugins/ -name "*-src.jar" -delete 2>/dev/null || true && \
    find plugins/ -name "sources.jar" -delete 2>/dev/null || true && \
    find . -name "*.pdf" -delete 2>/dev/null || true && \
    find . -name "*.md" -delete 2>/dev/null || true && \
    find . -name "*.html" -delete 2>/dev/null || true

# --- Download and Extract Gradle (bin distribution only) ---
ARG GRADLE_INSTALL_DIR=/opt/gradle
RUN mkdir -p ${GRADLE_INSTALL_DIR} && \
    curl -L "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -o /tmp/gradle.zip && \
    unzip -q /tmp/gradle.zip -d /tmp && \
    mv /tmp/gradle-${GRADLE_VERSION}/* ${GRADLE_INSTALL_DIR}/ && \
    rm -rf /tmp/gradle.zip /tmp/gradle-${GRADLE_VERSION} && \
    # Remove docs and samples
    rm -rf ${GRADLE_INSTALL_DIR}/docs \
           ${GRADLE_INSTALL_DIR}/samples \
           ${GRADLE_INSTALL_DIR}/src \
           ${GRADLE_INSTALL_DIR}/getting-started.html \
           ${GRADLE_INSTALL_DIR}/README \
           ${GRADLE_INSTALL_DIR}/LICENSE \
           ${GRADLE_INSTALL_DIR}/NOTICE

# --- Download and Extract Maven ---
ARG MAVEN_INSTALL_DIR=/opt/maven
RUN mkdir -p ${MAVEN_INSTALL_DIR} && \
    curl -L "https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" -o /tmp/maven.tar.gz && \
    tar -xzf /tmp/maven.tar.gz -C /tmp && \
    mv /tmp/apache-maven-${MAVEN_VERSION}/* ${MAVEN_INSTALL_DIR}/ && \
    rm -rf /tmp/maven.tar.gz /tmp/apache-maven-${MAVEN_VERSION} && \
    rm -rf ${MAVEN_INSTALL_DIR}/README.txt \
           ${MAVEN_INSTALL_DIR}/LICENSE \
           ${MAVEN_INSTALL_DIR}/NOTICE

# --- Download and Extract JExtract ---
ARG JEXTRACT_INSTALL_DIR=/opt/jextract
RUN mkdir -p ${JEXTRACT_INSTALL_DIR} && \
    curl -L "https://download.java.net/java/early_access/jextract/22/6/openjdk-22-jextract+6-47_linux-x64_bin.tar.gz" -o /tmp/jextract.tar.gz && \
    tar -xzf /tmp/jextract.tar.gz -C /tmp && \
    mv /tmp/jextract-22/* ${JEXTRACT_INSTALL_DIR}/ && \
    rm -rf /tmp/jextract.tar.gz /tmp/jextract-22

# --- Download Oracle JDK 25 ONLY ---
RUN curl -L "https://download.oracle.com/java/25/latest/jdk-25_linux-x64_bin.deb" -o /tmp/jdk-25.deb

# =================================================================================================
# STAGE 2: Final Production Image
# Base: NVIDIA TensorRT-LLM Devel
# =================================================================================================
FROM nvcr.io/nvidia/tensorrt-llm/devel:${TRT_LLM_VERSION}

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# --- 1. System Tools (Ordered by change frequency for better caching) ---
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # Core system tools (rarely change)
    openssh-server \
    sudo \
    nano \
    unzip \
    rsync \
    locales \
    passwd \
    # Development tools
    git \
    wget \
    curl \
    graphviz \
    fontconfig \
    man-db \
    htop \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

RUN rm -f /usr/lib/python3.*/EXTERNALLY-MANAGED

RUN locale-gen en_US.UTF-8

# --- 2. Install Oracle JDK 25 ONLY (Keep full installation) ---
COPY --from=builder /tmp/jdk-25.deb /tmp/jdk-25.deb
RUN dpkg -i /tmp/jdk-25.deb && \
    rm -f /tmp/jdk-25.deb && \
    ln -s "$(find /usr/lib/jvm -maxdepth 1 -name 'jdk-25.*' -type d | head -n 1)" /usr/lib/jvm/jdk-25 && \
    ls -ld /usr/lib/jvm/jdk-25/bin/java

# --- 3. Install Build Tools (Maven, Gradle, JExtract) ---
COPY --from=builder /opt/gradle /opt/gradle
COPY --from=builder /opt/maven /opt/maven
COPY --from=builder /opt/jextract /opt/jextract

# --- 4. Install IntelliJ IDEA Remote Server ---
ARG IDEA_INSTALL_DIR=/opt/jetbrains/idea
COPY --from=builder ${IDEA_INSTALL_DIR} ${IDEA_INSTALL_DIR}

# --- 5. Environment Configuration (Changes less frequently, good for caching) ---
ENV JAVA_HOME=/usr/lib/jvm/jdk-25
ENV GRADLE_HOME=/opt/gradle
ENV MAVEN_HOME=/opt/maven
ENV JEXTRACT_HOME=/opt/jextract

ENV PATH="${JAVA_HOME}/bin:${GRADLE_HOME}/bin:${MAVEN_HOME}/bin:${JEXTRACT_HOME}/bin:${PATH}"

# --- 6. SSH Configuration (System-level, changes rarely) ---
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo "PermitUserEnvironment yes" >> /etc/ssh/sshd_config && \
    mkdir -p /var/run/sshd && \
    ssh-keygen -A

# --- 7. User Configuration (Changes rarely) ---
RUN (userdel -r ubuntu 2>/dev/null || true) && \
    (groupdel ubuntu 2>/dev/null || true) && \
    groupadd -g 1000 developer && \
    useradd -u 1000 -g developer -m -s /bin/bash developer && \
    echo 'developer:password' | chpasswd && \
    usermod -aG sudo developer && \
    echo '%developer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# --- 8. Environment Inheritance (System-wide environment) ---
RUN echo "export PATH=${PATH}" >> /etc/profile && \
    echo "export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}" >> /etc/profile && \
    echo "export CUDA_HOME=${CUDA_HOME}" >> /etc/profile && \
    echo "export HPCX_DIR=${HPCX_DIR}" >> /etc/profile && \
    echo "export OPAL_PREFIX=${OPAL_PREFIX}" >> /etc/profile && \
    echo "export JAVA_HOME=${JAVA_HOME}" >> /etc/profile && \
    echo "export GRADLE_HOME=${GRADLE_HOME}" >> /etc/profile && \
    echo "export MAVEN_HOME=${MAVEN_HOME}" >> /etc/profile

# --- 9. Register IDE Backend (User-specific configuration) ---
USER developer
WORKDIR /home/developer

RUN echo "export SSH_AUTH_SOCK=/ssh-agent" > ~/.bashrc_temp && \
    ([ -f ~/.bashrc ] && cat ~/.bashrc >> ~/.bashrc_temp || true) && \
    mv ~/.bashrc_temp ~/.bashrc && \
    echo "export SSH_AUTH_SOCK=/ssh-agent" >> ~/.profile && \
    touch /home/developer/.hushlogin && \
    ${IDEA_INSTALL_DIR}/bin/remote-dev-server.sh registerBackendLocationForGateway

# --- 10. Final Setup ---
USER root

RUN mkdir -p /code && chown developer:developer /code

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 22
ENTRYPOINT ["entrypoint.sh"]