#!/usr/bin/env bash
this_dir="$( cd "$( dirname "$0" )" && pwd )"

if [[ -z "$1" ]]; then
    echo "Usage: upload-code.sh DIR"
    exit 1
fi

if [[ -z "$(which nodemcu-uploader)" ]]; then
    venv="$(realpath "${this_dir}/../.venv")"
    if [[ ! -d "${venv}" ]]; then
        bash "${this_dir}/create-venv.sh"
    fi

    source "${venv}/bin/activate"
fi

cd "$1" && \
    sudo nodemcu-uploader -p /dev/ttyUSB0 -b 115200 upload *.lua
