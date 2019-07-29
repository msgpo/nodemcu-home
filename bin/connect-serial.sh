#!/usr/bin/env bash
if [[ -z "$(which miniterm)" ]]; then
    venv="$(realpath "${this_dir}/../.venv")"
    if [[ ! -d "${venv}" ]]; then
        bash "${this_dir}/create-venv.sh"
    fi

    source "${venv}/bin/activate"
fi

sudo miniterm /dev/ttyUSB0 115200
