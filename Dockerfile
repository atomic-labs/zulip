FROM quay.io/sameersbn/ubuntu:latest
MAINTAINER Dean Chen <dean@atomic.vc>

ENV DATA_DIR="/data"

ADD docker/zulip-puppet /root/zulip-puppet

RUN wget -q -O /root/zulip-ppa.asc https://zulip.com/dist/keys/zulip-ppa.asc && \
    apt-key add /root/zulip-ppa.asc && \
    echo "deb http://ppa.launchpad.net/tabbott/zulip/ubuntu trusty main" > /etc/apt/sources.list.d/zulip.list && \
    echo "deb-src http://ppa.launchpad.net/tabbott/zulip/ubuntu trusty main" >> /etc/apt/sources.list.d/zulip.list && \
    apt-get -qq update && \
    apt-get -q dist-upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get -q install -y puppet git python-dev python-six python-pbs

ADD . /root/zulip

RUN mkdir -p "/root/zulip" "/etc/zulip" "$DATA_DIR" && \
    echo "[machine]\npuppet_classes = zulip::voyager\ndeploy_type = voyager" > /etc/zulip/zulip.conf && \
    rm -rf /root/zulip/puppet/zulip_internal /root/zulip/puppet/zulip && \
    mv -f /root/zulip-puppet /root/zulip/puppet/zulip && \
    /root/zulip/scripts/zulip-puppet-apply -f && \
    cp -fa /root/zulip/zproject/local_settings_template.py /etc/zulip/settings.py && \
    ln -nsf /etc/zulip/settings.py /root/zulip/zproject/local_settings.py && \
    ZULIP_DEPLOY_PATH="$(/root/zulip/zulip_tools.py make_deploy_path)" && \
    mv /root/zulip "$ZULIP_DEPLOY_PATH" && \
    ln -nsf "/home/zulip/deployments/next" /root/zulip && \
    ln -nsf "$ZULIP_DEPLOY_PATH" "/home/zulip/deployments/next" && \
    ln -nsf "$ZULIP_DEPLOY_PATH" "/home/zulip/deployments/current" && \
    ln -nsf /etc/zulip/settings.py "$ZULIP_DEPLOY_PATH/zproject/local_settings.py" && \
    /root/zulip/tools/update-prod-static && \
    cp -rfT "$ZULIP_DEPLOY_PATH/prod-static/serve" "/home/zulip/prod-static" && \
    chown -R zulip:zulip /home/zulip /var/log/zulip /etc/zulip/settings.py

VOLUME ["$DATA_DIR"]
EXPOSE 80 443

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["app:run"]
