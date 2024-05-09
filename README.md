# Go Code Coverage Report

```yaml
permissions:
  contents: write
  pull-requests: write

jobs:

  coverage:
    name: Generate Coverage Report
    runs-on: ubuntu-latest
    
    steps:
      - name: Get Code Coverage
        uses: sonichigo/get-cov@main
        with:
            coverage-file: my-coverage-file
            coverage-threshold: 55
            token: ${{ secrets.GITHUB_TOKEN }}
```