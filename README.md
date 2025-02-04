# AWS CDK Dockerized Environment Template

This is a template for a dockerized environment for CDK projects (typescript)

The main benefits are:

- no need to install much thing on your machine
- good for big team with new joiners for a fast start (you only have to share the info to connect to aws, like your sso endpoint and region, or aws access keys)
- can allow you to setup quick poc running in cloud without thinking much about initial setup

## Requirements

- docker
- docker compose
- make
- bash

## Bootstrap a new project from this template

```bash
git clone git@github.com:PaulSenon/tpl-aws-cdk-dockerized-dev-env.git YOUR_PROJECT_NAME && \
cd YOUR_PROJECT_NAME && \
./bootstrap.sh && \
rm ./bootstrap.sh
```

## Contributions

Feel free to contribute to this template by opening a PR or an issue.

## License

Apache 2.0 - Help yourself to this template and use it as you want.

## TODO

- [ ] better error handling on weird node version values
- [ ] test with yarn
- [ ] test with npm
- [ ] test on windows (with wsl)
- [ ] test on linux
- [ ] finish final readme
- [ ] add github actions to deploy and destroy the stack
