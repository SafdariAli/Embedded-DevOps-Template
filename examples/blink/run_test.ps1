docker run --rm -it `
  -v "${PWD}\..\..\:/workspace" `
  -w /workspace/examples/blink `
  embedded-tdd:1.0.0 `
  ceedling test:all