FROM pytorch/pytorch:2.4.0-cuda11.8-cudnn9-runtime
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

RUN apt-get update
RUN apt-get install --fix-missing -y -q --no-install-recommends gnupg2 dirmngr software-properties-common lsb-release wget libgomp1 ffmpeg libsm6 libxext6 pdftohtml git ninja-build g++ qpdf pandoc

RUN add-apt-repository ppa:alex-p/tesseract-ocr5 && apt-get update

RUN apt-get install -y ocrmypdf tesseract-ocr \
    tesseract-ocr-fra \
    tesseract-ocr-spa \
    tesseract-ocr-deu \
    tesseract-ocr-ara \
    tesseract-ocr-mya \
    tesseract-ocr-hin \
    tesseract-ocr-tam \
    tesseract-ocr-tha \
    tesseract-ocr-chi-sim \
    tesseract-ocr-tur \
    tesseract-ocr-ukr \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app/src
RUN mkdir -p /app/models

RUN addgroup --system python && adduser --system --group python
RUN chown -R python:python /app
USER python

ENV VIRTUAL_ENV=/app/.venv
RUN python -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

COPY requirements.txt requirements.txt
RUN uv pip install --upgrade pip
RUN uv pip install -r requirements.txt

WORKDIR /app
RUN cd src; git clone https://github.com/facebookresearch/detectron2;
RUN cd src/detectron2; git checkout 70f454304e1a38378200459dd2dbca0f0f4a5ab4; python setup.py build develop
RUN uv pip install pycocotools==2.0.8

COPY ./start.sh ./start.sh
COPY ./src/. ./src
COPY ./models/. ./models/
RUN python src/download_models.py

ENV PYTHONPATH "${PYTHONPATH}:/app/src"
ENV TRANSFORMERS_VERBOSITY=error
ENV TRANSFORMERS_NO_ADVISORY_WARNINGS=1

