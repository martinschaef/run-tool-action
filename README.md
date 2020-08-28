# Test action to sync the repo to S3 and then call a lambda


### Example usage

Example how to use this acation to upload a mvn build to s3 and then call a lambda:

```
name: Run Lambda on Artifact
on:
  # push:
  #   branches: [ master ]
  pull_request:
    branches: [ master ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master      
    - name: Set up JDK 1.8
      uses: actions/setup-java@v1
      with:
        java-version: 1.8
    - run: mvn -B package --file pom.xml
    - name: Run Lambda on Artifact
      uses: martinschaef/run-tool-action@v0.0.9
      env:
        AWS_LAMBDA_NAME: ${{ secrets.AWS_LAMBDA_NAME }}
        AWS_S3_BUCKET: ${{ secrets.AWS_S3_BUCKET }}
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AWS_REGION: 'us-west-2'
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    - name: comment PR
      uses: unsplash/comment-on-pr@master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        msg: "We can also comment from here"
        check_for_duplicate_msg: false  # OPTIONAL 
```



