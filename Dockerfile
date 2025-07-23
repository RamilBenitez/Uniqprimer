FROM python:3.9-slim

# Set noninteractive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Set workdir
WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget build-essential emboss \
    libexpat1 libgomp1 perl git \
    && rm -rf /var/lib/apt/lists/*

# Install MUMmer 3.23
RUN wget https://downloads.sourceforge.net/project/mummer/mummer/3.23/MUMmer3.23.tar.gz && \
    tar -xzf MUMmer3.23.tar.gz && \
    mv MUMmer3.23 /opt/mummer && \
    make -C /opt/mummer && \
    cp /opt/mummer/nucmer /usr/local/bin/ && \
    cp /opt/mummer/delta-filter /usr/local/bin/ && \
    cp /opt/mummer/show-coords /usr/local/bin/ && \
    mkdir -p /app/MUMmer3.23/scripts && \
    cp -r /opt/mummer/scripts/* /app/MUMmer3.23/scripts && \
    rm -rf MUMmer3.23.tar.gz

ENV PERL5LIB=/app/MUMmer3.23/scripts


# Install Primer3 v1.1.4
RUN wget https://github.com/primer3-org/primer3/archive/refs/tags/v1.1.4.tar.gz -O primer3-1.1.4.tar.gz && \
    tar -xzf primer3-1.1.4.tar.gz && \
    cd primer3-1.1.4/src && \
    make && \
    cp primer3_core /usr/local/bin/ && \
    cd ../.. && rm -rf primer3-1.1.4*

# Copy all project files
COPY . /app/

# Install Python packages
RUN pip install --no-cache-dir biopython==1.76 numpy==1.21.0 && \
    cd /app/uniqprimer-0.5.0 && \
    python3 setup.py install && \
    echo "/app/uniqprimer-0.5.0" > /usr/local/lib/python3.9/site-packages/primertools.pth

# Make scripts executable
RUN chmod +x /app/uniqprimer.sh

# Set environment variables (optional but helpful)
ENV PATH="/app/uniqprimer-0.5.0:$PATH"
ENV PYTHONPATH="/app/uniqprimer-0.5.0:$PYTHONPATH"
ENV TMPDIR=/tmp/uniqprimer

# Entrypoint (runs the main shell script)
ENTRYPOINT ["/app/uniqprimer.sh"]