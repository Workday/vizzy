![vizzy-logo-3x](https://user-images.githubusercontent.com/1944329/38047018-ffe4638a-3275-11e8-8385-68c15493a908.png)

[![Build Status](https://travis-ci.org/Workday/vizzy.svg?branch=master)](https://travis-ci.org/Workday/vizzy)

Vizzy is a powerful Ruby on Rails web server that facilitates Visual Automation, a continuous integration testing strategy that aims to prevent visual regressions. It does this by performing pixel by pixel comparisons of screenshots captured during test runs. In doing so, it tests application data as well as application views. In order to harness the full power of Vizzy, there are two major prerequisites:

1. A build pipeline that runs tests on pull requests.
2. A client testing framework that enables developers to easily write tests that can access the application's views, capture images of them, and save those images to a directory.

The process Vizzy goes through is as follows:

1. First a test suite is run against the master branch. This generates a set of images which becomes the baseline to test against. These "Base Images" are uploaded and managed by Vizzy. 

2. Then for every subsequent pull request changeset, the same test suite runs and generates a new set of images called "Test Images". MD5 hashes are created from the images so only the images that are different from their base image get uploaded. Vizzy goes through each matching test, which contains two images, one base image and one test image, and performs a pixel by pixel diff of the two images using a tool called [ImageMagick](https://rubygems.org/gems/rmagick/versions/2.15.4). A third image is generated which highlights the differences in red. 

3. After all diffs are calculated, Vizzy updates a Github status with the link to the visual overview. It displays: diffs, new tests, missing tests, test history, comments, and the ability to approve test images. The developer is then presented with the option to approve the differences if the changes were intentional, or to fix, commit, and rerun visual automation if the changes were unintentional or indicate a bug. Once the pull request is merged and subsequent master build finishes, the approved images replace the base images for those tests, and subsequent visual tests are compared against these new images. Large development teams can run multiple builds simultaneously because the base image set always matches the master branch. 

Vizzy is built with a plugin architecture. Plugins implement build hooks (build_created, build_committed, build_failed) to achieve a task. Slack, Jira, Bamboo, and Jenkins plugins are provided and configurable.

[Vizzy Client-Server Diagram](https://user-images.githubusercontent.com/1944329/38047014-ff889078-3275-11e8-9b02-53fa9591e0f7.png)

## Getting Started
### Prerequisites
Ruby 2.3.1 and Rails 5.1.4. See http://installrails.com/ for install instructions.

#### Install ImageMagick and PostgreSQL
Install ImageMagick, a command line image processing tool (version 6 is required as the latest version causes bundle install to fail):

```
brew unlink imagemagick
brew install imagemagick@6 && brew link imagemagick@6 --force
```

Install the PostgreSQL database:

`brew install postgres`

PostgreSQL is a database server, so you'll need to start it up to run Vizzy.

`brew services start postgresql`

### Setup
Vizzy uses Rails 5.1 encrypted secrets for its configuration. From the Vizzy project directory, run these commands

Generate the encrypted secrets file and key.

```
bin/rails secrets:setup
```
Do not check in the encryption key into the repository, add it to the project with an environment variable called `RAILS_MASTER_KEY`. For more information you can go to this [blog post](https://www.engineyard.com/blog/encrypted-rails-secrets-on-rails-5.1).

Add secrets to the yaml file by running the following command: *Note*: you may specify for your favorite editor.
```
EDITOR=vi bin/rails secrets:edit
```
If you see an error `Devise.secret_key was not set` you will have to add the sample secret_key to [devise.rb](/config/initializers/devise.rb), run the setup/edit, then remove the Devise.secret_key. Devise now uses the project secret_key_base.

Here are the possible secrets:

```yaml
shared:
  # Required Secrets
  POSTGRES_USER: "postgres_database"
  POSTGRES_PWD: "postgres_database_password"
  GITHUB_AUTH_TOKEN: "auth_token_value"
  ADMIN_EMAILS: "email1@gmail.com, email2@gmail.com"
  # Optional Plugin Secrets
  BAMBOO_USERNAME: "bamboo_username"
  BAMBOO_PASSWORD: "bamboo_password"
  JIRA_USERNAME: "jira_username"
  JIRA_PASSWORD: "jira_password"
  SLACK_WEBHOOK: "slack_webhook_value"
  BUGSNAG_API_KEY: "bugsnag_api_key_value"
  # Required To Run System Tests
  GITHUB_ROOT_URL: "live_github_url"
  GITHUB_REPO: "live_github_repo"
  JIRA_PROJECT: "live_jira_project"
  JIRA_BASE_URL: "live_jira_base_url"
  BAMBOO_BASE_URL: "live_bamoo_base_url"

development:
  secret_key_base: "XXXXX1"

test:
  secret_key_base: "XXXXX2"

ci_test:
  secret_key_base: "XXXXX3"

production:
  secret_key_base: "XXXXX4"
```
To generate new instances of `secret_key_base` run `rake secret` 4 times and copy/paste the values above. Upon saving this file, a file called `secrets.yml.enc` will be created.

### Configure Authentication Type
To configure open [vizzy.yaml](config/vizzy.yaml)

For local authentication with user registration, no setup is required. The default auth strategy is local.
```yaml
defaults: &default
  devise:
    auth_strategy: 'local'
```

For LDAP authentication/account lookup, configure your LDAP auth server.
```yaml
defaults: &default
  devise:
    auth_strategy: 'LDAP'
    ldap_email_domain: '@domain.com'
    ldap_host: 'host_ip_address'
    ldap_port: 'host_port'
    ldap_base: 'DC=domaininternal,DC=com'
    ldap_email_internal_domain: '@domaininternal.com'
    password_placeholder: "LDAP Password"
```

### Create and Migrate the Database
From the Vizzy project directory run

`rake db:create db:migrate`

### Create a Vizzy Project and Test User

Vizzy projects allow you to run visual automation on multiple branches (ex. Master, Develop), each branch represented by a project. Each project has its own set of base images. There is typically a one to one mapping of a build plan to a Vizzy project. NOTE: Pull Requests opened against the master branch should be uploaded to the master Vizzy project so the correct set of base images are used to calculated the diffs.  

To create a test project for development, I recommend seeding the database. Vizzy uses [FactoryBot](https://github.com/thoughtbot/factory_bot) to add test data. Add your Github information (required) as well as plugin settings (optional) to the project factory [project.rb](test/factories/projects.rb).

Then run `rake db:reset` which will clear the database, run the migrations, and populate the database with the test data in [seeds.rb](db/seeds.rb)(sample user and project). You could also achieve this by running `rake db:seed` if you don't want to clear the database.

You can also create a user account and navigate to http://0.0.0.0:3000/projects to create a new project once the server is running.

### Create a Rails Run Configuration in your IDE ([RubyMine](https://www.jetbrains.com/ruby/))
Run the server in development mode. Settings are straightforward.

<img width="592" alt="vizzy_development_run_configuration" src="https://user-images.githubusercontent.com/1944329/38047015-ffa7a4ea-3275-11e8-972c-cede06d01098.png">

Navigate to http://0.0.0.0:3000 to see the running server.

### Run Simulated Test Builds
There are 3 sets of sample images in /test-image-upload. There is an utility script [run_test_push.rb](test-image-upload/run_test_push.rb) to make running test builds easier. It only takes 2 parameters: `Test Case` and `Is Master`. Here are the 6 possible combinations which are easy to setup as Ruby Run Configurations. 

| Name | Test Case | Is Master |
| --- | --- | --- |
| Master 1 | 1 | 1 |
| Master 2 | 2 | 1 |
| Master 3 | 3 | 1 |
| Pull Request 1 | 1 | 2 |
| Pull Request 2 | 2 | 2 |
| Pull Request 3 | 3 | 2 |

Here is a sample run config for Master 1:

<img width="592" alt="master_1_build_configuration" src="https://user-images.githubusercontent.com/1944329/38047013-ff6968a6-3275-11e8-953f-96a30e5ac020.png">

## Deployment

This server is docker ready and can be deployed with any tool you want.

- [Dockerfile](Dockerfile): Builds dependencies, adds the source code, precompiles the assets, and exposes port 3000.

Travis CI publishes the latest master image to [Docker Hub](https://hub.docker.com/r/scottcbishop/vizzy/)

We recommend a tool called [Kubernetes](https://kubernetes.io/docs/home/) (k8s), an opened sourced container cluster manager originally designed by Google, now owned by Cloud Native Computing. This tool aims to 
provide a platform for automating deployment, scaling, and operations of application containers across clusters of hosts.

Kubernetes scripts are provided in the [k8s](./k8s) folder. Here is an example for running the k8s deployment script. 

*NOTE*: some parameters will come from the Continuous Integration (CI) build system such as $GIT_COMMIT.

```sh
API_SERVER=https://kubernetes-api-server.com
NAMESPACE=vizzy
REPLICA_PODS=5
VIZZY_URI=vizzy.com
MEMORY="8Gi"
RAILS_ENV=production
DOCKER_REGISTRY=dockerhub.com
RUN_TESTS=false

./deploy-vizzy.sh --api-server=$API_SERVER --bearer-token=$BEARER --rails-env=$RAILS_ENV --vizzy-version=$GIT_COMMIT --namespace=$NAMESPACE --vizzy-uri=$VIZZY_URI --replica-pods=$REPLICA_PODS --memory=$MEMORY --docker-registry=$DOCKER_REGISTRY --run-tests=$RUN_TESTS
```

### Our Current Deployment Setup

1 Pod for Postgres database
5 Pods for the Vizzy server

All pods are assigned an IP/Host in the data center and share:

- A persistent volume (PVC - on the main host machine) which is mounted on every pod. All pods read and write images with this volume so as a user, no matter which of the 5 pods you connect to, images will 
all be loaded correctly.
- A single Postgres database shared for all pods.

## Add Upload Step to Continuous Integration Builds

Vizzy contains the upload script in the public directory [upload_images_to_server.rb](test-image-upload/upload_images_to_server.rb). To obtain the upload script in your CI builds, you can download it from the running server with this shell script

```sh
vizzy_endpoint="$1"
if [ -z "$vizzy_endpoint" ]; then
    echo "No Vizzy endpoint given. Usage: './download_upload_script.sh <vizzy-endpoint>'"
    exit 1
fi
echo "Downloading from $vizzy_endpoint/upload_images_to_server.rb"
curl -O "$vizzy_endpoint/upload_images_to_server.rb"
chmod a+x ./upload_images_to_server.rb
```
This allows the upload script to be versioned with the server.

There are 4 script options. Open is only used for creating Dev Builds and is not needed on CI builds.

Usage: upload_images_to_server.rb command [options]
  Available commands are:
   create:     Creates a new build with the server. Saves build information in json into a provided file path
   upload:     Upload provided images. Reads in build information from a file (as generated by the 'create' command)
   open:       Opens a visual build in a browser referenced in the build information file as generated by the 'create' command. 
   fail:       Fail the build referenced in the build information file as generated by the 'create' command )

See 'upload_images_to_server.rb COMMAND --help' for more information on a specific command.
    -h, --help                       Show this message

### Examples using Bamboo CI
#### Create Vizzy Build
```sh

VISUAL_HOST=https://vizzy.com
PLAN_KEY=${bamboo.planKey}
BUILD_NUMBER=${bamboo.buildNumber}
PLAN_TITLE=$PLAN_KEY-$BUILD_NUMBER
BUILD_URL="https://bamboo.com/browse/$PLAN_TITLE"
GIT_HASH=${bamboo.planRepository.1.revision}
VIZZY_USER_EMAIL=${bamboo.VIZZY_USER_EMAIL}
VIZZY_USER_TOKEN=${bamboo.VIZZY_USER_TOKEN_PASSWORD}

ruby ./upload_images_to_server.rb create $VISUAL_HOST --title "$PLAN_TITLE" --project 1 --commit "$GIT_HASH" --file ./visual-build-info --url "$BUILD_URL" --user-email "$VIZZY_USER_EMAIL" --user-token "$VIZZY_USER_TOKEN"
```

#### Upload Images To Vizzy
```sh
#!/bin/sh
VISUAL_HOST=https://vizzy.com
TEST_IMAGE_DIR="../../android/application/visual-automation-test-images/visual-automation-device-images"
VIZZY_USER_EMAIL=${bamboo.VIZZY_USER_EMAIL}
VIZZY_USER_TOKEN=${bamboo.VIZZY_USER_TOKEN_PASSWORD}
ruby ./upload_images_to_server.rb upload $VISUAL_HOST --directory "$TEST_IMAGE_DIR" --file ./visual-build-info --user-email "$VIZZY_USER_EMAIL" --user-token "$VIZZY_USER_TOKEN"
```

#### Fail Vizzy Build
If your CI build fails at any time, you can notify Vizzy with a failure message
```sh
VISUAL_HOST=https://vizzy.com
    VIZZY_USER_EMAIL=${bamboo.VIZZY_USER_EMAIL}
    VIZZY_USER_TOKEN=${bamboo.VIZZY_USER_TOKEN_PASSWORD}
    ruby ./upload_images_to_server.rb fail "$VISUAL_HOST" --message "Build Failed!" --file ./visual-build-info --user-email "$VIZZY_USER_EMAIL" --user-token "$VIZZY_USER_TOKEN"
```

### Disable squash merging
Squashing your commits when merging a pull request will break pre-approvals. This is because Vizzy uses the commit sha of the pull request and stores it with each image approval. Squash and merge will create a NEW merge commit and remove the commit sha that was used for approvals.

To disable this setting, go to the Github repository settings, and uncheck `Allow squash merging`

### Non-Deterministic Challenges
Turn off Animations for test suites: taking screenshots of animations does not always capture the same image which will cause visual diffs. 

Mock Dynamic Data: taking screenshots that contain dates will change day to day and cause visual diffs.

### Testing
Unit tests are run with the command
 
```rake test```

In order to run System tests, fill out the system test encrypted secrets. System tests are run with the command
 
```rails test:system```

## Slack Workspace
Join the developer community
https://join.slack.com/t/vizzy-dev/shared_invite/enQtMzQxMzI4MjE5MTA3LTNmM2U5MzgzN2U4NzIxZTMzNDI2ZjE5ZDNmNTBhYzUxYzFiMGIzNjE0YWNiYjRlZjhhNWM5YjAzOGViNDA5YzQ

## Contributing

1. Fork the repo!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D
