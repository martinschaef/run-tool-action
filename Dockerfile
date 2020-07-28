FROM python:3.8-alpine

LABEL "com.github.actions.name"="Comment With Lambda"
LABEL "com.github.actions.description"="Syncs build to S3, runs a lambda and comments with the output of the Lambda"
LABEL "com.github.actions.icon"="refresh-cw"
LABEL "com.github.actions.color"="green"

# https://github.com/aws/aws-cli/blob/master/CHANGELOG.rst
ENV AWSCLI_VERSION='1.18.14'

RUN pip install --quiet --no-cache-dir awscli==${AWSCLI_VERSION}
RUN gem install octokit

ADD entrypoint.sh /entrypoint.sh
ADD comment.sh /comment.sh
ENTRYPOINT ["/entrypoint.sh"]
