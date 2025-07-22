FROM python:3.12-alpine3.19

RUN apk add --no-cache gcc musl-dev libffi-dev

WORKDIR /app

COPY . .

RUN pip install --no-cache-dir fastapi uvicorn[standard]

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
