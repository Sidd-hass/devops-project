# Use a small base image
FROM python:3.11-slim AS base


WORKDIR /app


# system deps (kept minimal)
RUN apt-get update \
&& apt-get install -y --no-install-recommends build-essential ca-certificates \
&& rm -rf /var/lib/apt/lists/*


# copy requirements and install
FROM base AS builder
COPY app/requirements.txt /app/requirements.txt
RUN pip install --upgrade pip && pip install --no-cache-dir -r /app/requirements.txt


# final image
FROM base
WORKDIR /app

# Copy installed packages AND executables
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

COPY app /app

ENV PORT=5000
EXPOSE 5000
CMD ["gunicorn", "-b", "0.0.0.0:5000", "main:app", "--workers=2"]
