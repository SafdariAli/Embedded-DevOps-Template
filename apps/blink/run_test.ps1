docker run --rm -it `
  -v "${PWD}\:/workspace" `
  -w /workspace/ `
  safdariali/ceedling:latest `
  ceedling test:all
  
  Remove-Item .\build -Recurse -Force