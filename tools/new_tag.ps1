# tools/new_tag.ps1 — Crea tag (ej. v0.02.0) con mensaje
param([Parameter(Mandatory=\True)][string]\,[string]\='release')
git tag -a \ -m \
git push origin \
