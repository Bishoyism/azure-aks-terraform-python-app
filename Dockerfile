# Use build ARG to make platform configurable
ARG TARGETPLATFORM
FROM --platform=$TARGETPLATFORM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

# Saperated gunicorn installation and permission fix
RUN pip install gunicorn && \
    chmod +x /usr/local/bin/gunicorn

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app.main:app"]