FROM infobyte/faraday

RUN pip install --upgrade pip

COPY ./files/run_faraday.sh /root/run_faraday.sh
RUN chmod 755 /root/*.sh

#CMD /root/run-gui.sh
CMD ["/bin/bash"]