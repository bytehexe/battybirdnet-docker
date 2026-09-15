FROM python:3.9-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        ffmpeg \
        sox \
        git \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ARG REPO_URL=https://github.com/rdz-oss/BattyBirdNET-Analyzer.git
ARG REPO_REF=main
RUN git clone --depth 1 --branch "${REPO_REF}" "${REPO_URL}" .

# Upstream bug: the --area whitelist in server.py's set_analysis_location() omits
# "EU" and "Scotland", even though both have working elif branches below it and
# bundled checkpoints under checkpoints/bats/v1.0/. The whitelist check runs first
# and exits with "Unknown location option." before the elif chain is ever reached.
# Patch the guard so EU and Scotland are accepted like the other areas.
RUN sed -i \
        's/\["Bavaria", "South-Wales", "UK", "USA","USA-EAST","USA-WEST","BIRDS","CUSTOM_BIRD","CUSTOM_BAT"\]/["Bavaria", "EU", "Scotland", "South-Wales", "UK", "USA","USA-EAST","USA-WEST","BIRDS","CUSTOM_BIRD","CUSTOM_BAT"]/' \
        server.py \
    && grep -q '"EU"' server.py \
    && grep -q '"Scotland"' server.py

RUN pip3 install --no-cache-dir numpy scipy librosa bottle resampy tensorflow

RUN mkdir -p uploads

EXPOSE 7667

ENTRYPOINT ["python3", "server.py"]
CMD ["--host", "0.0.0.0", "--port", "7667", "--area", "EU"]
