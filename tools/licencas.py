"""Gera docs/LICENCAS_DE_TERCEIROS.md: dependências do app (Rust da ponte + Dart de produção) e suas licenças.

Uso (na pasta Genoz):  python -X utf8 tools/licencas.py
Falha (código 1) se aparecer licença copyleft forte (GPL/AGPL) dentro do app.
"""
import json
import os
import re
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent
app = root / 'app'
FLUTTER = 'flutter.bat' if os.name == 'nt' else 'flutter'


def rust_crates():
    meta = json.loads(subprocess.run(['cargo', 'metadata', '--format-version', '1', '--filter-platform', 'aarch64-linux-android'],
                                     cwd=app / 'rust', capture_output=True, text=True, check=True).stdout)
    # Só o que entra no binário: dependências normais alcançáveis a partir da ponte.
    nodes = {n['id']: n for n in meta['resolve']['nodes']}
    pkgs = {p['id']: p for p in meta['packages']}
    root_id = meta['resolve']['root']
    seen, stack = set(), [root_id]
    while stack:
        i = stack.pop()
        if i in seen:
            continue
        seen.add(i)
        for d in nodes[i]['deps']:
            if any(k['kind'] is None for k in d['dep_kinds']):
                stack.append(d['pkg'])
    out = []
    for i in seen:
        p = pkgs[i]
        if p['source'] is None:
            continue  # os nossos (genoz_core, ponte)
        lic = p.get('license')
        if not lic and p.get('license_file'):
            # Sem o campo `license`: lê o arquivo indicado no Cargo.toml.
            f = Path(p['manifest_path']).parent / p['license_file']
            lic = guess(f.read_text(encoding='utf-8', errors='replace')) if f.exists() else '?'
        out.append((p['name'], p['version'], lic or '?'))
    return sorted(out)


def guess(text):
    t = text.lower()
    # MPL antes de GNU: o texto da MPL 2.0 cita as licenças GNU como "licenças secundárias".
    if 'mozilla public license' in t:
        return 'MPL-2.0'
    if 'gnu affero' in t:
        return 'AGPL'
    if 'gnu lesser' in t or 'gnu library general' in t:
        return 'LGPL'
    if 'gnu general public license' in t:
        return 'GPL'
    if 'apache license' in t:
        return 'Apache-2.0'
    if 'permission is hereby granted, free of charge' in t:
        return 'MIT'
    if 'redistribution and use in source and binary forms' in t:
        return 'BSD-3-Clause' if 'neither the name' in t or 'name of' in t else 'BSD-2-Clause'
    if 'zlib' in t and 'altered source versions' in t:
        return 'Zlib'
    return '?'


def dart_packages():
    deps = json.loads(subprocess.run([FLUTTER, 'pub', 'deps', '--json'], cwd=app, capture_output=True,
                                     text=True, check=True, shell=os.name == 'nt').stdout)
    # Só o que o app usa em produção: alcançável a partir das dependências (não das de desenvolvimento).
    by_name = {p['name']: p for p in deps['packages']}
    root_pkg = next(p for p in deps['packages'] if p['kind'] == 'root')
    reach, stack = set(), list(root_pkg['dependencies'])
    while stack:
        n = stack.pop()
        if n in reach or n not in by_name:
            continue
        reach.add(n)
        stack.extend(by_name[n].get('dependencies', []))
    config = json.loads((app / '.dart_tool' / 'package_config.json').read_text(encoding='utf-8'))
    where = {}
    for p in config['packages']:
        uri = p['rootUri']
        if uri.startswith('file:///'):
            path = uri[len('file:///'):]
        else:
            path = str((app / '.dart_tool' / uri).resolve())
        where[p['name']] = Path(path.replace('%20', ' '))
    out = []
    for p in deps['packages']:
        if p['name'] not in reach or p.get('source') in ('sdk', 'path'):
            continue
        d = where.get(p['name'])
        lic = '?'
        if d:
            for name in ('LICENSE', 'LICENSE.md', 'LICENSE.txt', 'COPYING'):
                f = d / name
                if f.exists():
                    lic = guess(f.read_text(encoding='utf-8', errors='replace'))
                    break
        out.append((p['name'], p['version'], lic))
    return sorted(out)


rust = rust_crates()
dart = dart_packages()
bad = [(n, v, l) for n, v, l in rust + dart if re.search(r'\b(A?GPL)', l) and 'LGPL' not in l and ' OR ' not in l]
lines = ['# Licenças de terceiros', '',
         'Gerado por `tools/licencas.py` — dependências que entram no app (Rust da ponte, alvo Android; '
         'pacotes Dart de produção). As licenças completas aparecem no app em **Sobre → Licenças**.', '',
         f'Resultado: {len(rust)} crates Rust e {len(dart)} pacotes Dart; '
         + ('**nenhuma licença copyleft forte (GPL/AGPL)**.' if not bad else f'**ATENÇÃO: {bad}**'), '',
         '## Rust', '', '| Crate | Versão | Licença |', '|---|---|---|']
lines += [f'| {n} | {v} | {l} |' for n, v, l in rust]
lines += ['', '## Dart', '', '| Pacote | Versão | Licença (detectada no arquivo LICENSE) |', '|---|---|---|']
lines += [f'| {n} | {v} | {l} |' for n, v, l in dart]
(root / 'docs' / 'LICENCAS_DE_TERCEIROS.md').write_text('\n'.join(lines) + '\n', encoding='utf-8', newline='\n')
unknown = [n for n, _, l in rust + dart if l == '?']
print(f'rust {len(rust)}, dart {len(dart)}, desconhecidas: {unknown}, copyleft forte: {bad}')
sys.exit(1 if bad else 0)
