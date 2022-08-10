FROM python:3.8
RUN adduser user
COPY . /srv
RUN pip install --upgrade pip && pip install --no-cache -r /srv/requirements.txt
WORKDIR /srv
# USER user
CMD [ "jupyter", "lab", "--ip", "0.0.0.0", "--no-browser", "--allow-root" ]