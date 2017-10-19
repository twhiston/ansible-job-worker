FROM openshift/base-centos7

MAINTAINER Tom Whiston <tom.whiston@gmail.com>

LABEL io.k8s.description="Centos7 based ansible runner" \
      io.k8s.display-name="ansible" \
      io.openshift.tags="ansible,automation,cronjob,job,${BUILD_ENV}"

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH
COPY ./contrib/ ${HOME}


RUN yum -y install epel-release && yum clean all && \
    yum install -y --setopt=tsflags=nodocs \
    git ansible rsync curl python-pip nss_wrapper  \
    && yum clean all \
    && pip install -U boto \
    && mkdir ${HOME}/.ssh \
    && chown -R 1001:0 ${HOME}

USER 1001

ENTRYPOINT ["/opt/app-root/src/container-entrypoint"]
CMD $STI_SCRIPTS_PATH/usage

