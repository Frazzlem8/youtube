FROM python:3.13-alpine

RUN adduser -D -h /sandbox sandbox

WORKDIR /app
COPY app.py .

EXPOSE 8080
USER sandbox
CMD ["python", "app.py"]
