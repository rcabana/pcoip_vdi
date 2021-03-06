FROM centos:7
LABEL maintainer="roland.cabana@vaultsystems.com.au"
COPY CM-1.8.1_SG-1.14.1/Connection_Manager_Security_Gateway/* /opt/
RUN /opt/cm_setup.sh
COPY SecurityGateway.conf /etc/
COPY ConnectionManager.conf /etc/
ENTRYPOINT /etc/init.d/connection_manager start && /etc/init.d/security_gateway start
