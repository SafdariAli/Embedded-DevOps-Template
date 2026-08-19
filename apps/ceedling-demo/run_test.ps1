docker run --rm -it `
  -v "${PWD}\:/workspace" `
  -w /workspace/ `
  safdariali/ceedling:latest `
  ceedling test:all

if (Test-Path .\build) { Remove-Item -Path .\build -Recurse -Force }