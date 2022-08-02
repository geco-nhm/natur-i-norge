FROM python:3.10
# RUN apt-get update && \
#     apt-get install -y vim && \
#     adduser user
RUN adduser user
USER user
ENV PATH=/home/user/.local/bin/:$PATH
COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir -r /requirements.txt
EXPOSE 8888
COPY partial/04_species_urls.csv /input/species_urls.csv
COPY 05_get_images.py srv/get_images.py
COPY secret/ /srv/secret/
WORKDIR /srv
CMD ["python", "/srv/get_images.py"]
# CMD [ "jupyter", "lab", "--ip", "0.0.0.0", "--no-browser" ]