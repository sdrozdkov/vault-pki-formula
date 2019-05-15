# -*- coding: utf-8 -*-
#
#   Copyright 2018 Ripple Labs, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# vim: set ft=sls :

{% set os_family = grains['os_family'] -%}


python3-pip:
  pkg.installed:
    - pkgs:
      - python3-pip

setup new cert-access group:
  group.present:
    - name: cert-access

install crypto dependencies:
  pkg.installed:
    - pkgs:
      - python3-dev
      - libssl-dev
      - libffi-dev

install python cryptography module:
  pip.installed:
    - name: cryptography
    - bin_env: /usr/bin/pip3
    - reload_modules: true
    - require:
      - python3-pip

/usr/local/bin/vault_pki:
  file.managed:
    - source: salt://cert/files/vault_pki.py
    - user: root
    - group: root
    - mode: 0755

install python salt lib module:
  pip.installed:
    - name: salt
    - bin_env: /usr/bin/pip3
    - reload_modules: true
    - require:
      - python3-pip

run vault_pki to get initial cert:
  cmd.run:
    - name: /usr/local/bin/vault_pki checkgen
    - require:
      - group: setup new cert-access group
      - pkg: install crypto dependencies
      - pip: install python cryptography module
      - pip: install python salt lib module
      - file: /usr/local/bin/vault_pki

checkgen_cert:
  cron.present:
    - name: (/usr/local/bin/vault_pki list ; /usr/local/bin/vault_pki checkgen ; /usr/local/bin/vault_pki list) 2>&1 | logger -t vault_pki
    - identifier: checkgen_cert
    - user: root
    - hour: random
    - minute: random
    - require:
      - file: /usr/local/bin/vault_pki
