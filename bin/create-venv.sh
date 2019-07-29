#!/usr/bin/env bash
this_dir="$( cd "$( dirname "$0" )" && pwd )"

venv="$(realpath "${this_dir}/../.venv")"
if [[ ! -d "${venv}" ]]; then
    if [[ -z "$(which virtualenv)" ]]; then
        sudo apt-get install python-virtualenv
    fi

    virtualenv "${venv}"
fi

source "${venv}/bin/activate"
pip install -r "${this_dir}/../requirements.txt"
