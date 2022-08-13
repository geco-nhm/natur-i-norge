FROM python:3.10
# RUN apt-get update && \
#     apt-get install -y vim
ENV PATH=/home/user/.local/bin/:$PATH
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt
EXPOSE 8888
WORKDIR /src
CMD [ "jupyter", "lab", "--ip", "0.0.0.0", "--no-browser", "--allow-root" ]
