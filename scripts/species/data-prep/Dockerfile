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
COPY partial/species_urls.csv /input/species_urls.csv
RUN mkdir -p /home/user/tmp
COPY --chown=user 05_get_images.py home/user/get_images.py
COPY secret/ /srv/secret/
WORKDIR /home/user
CMD ["python", "/home/user/get_images.py"]
# CMD [ "jupyter", "lab", "--ip", "0.0.0.0", "--no-browser" ]