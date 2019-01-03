workflow "Deploy" {
  on = "push"
  resolves = [
    "Build docker image",
    "Auth Google",
    "Tag image for GCR",
    "Push image to GCR"
  ]
}

action "Build docker image" {
  uses = "actions/docker/cli@master"
  args = ["build", "-t", "api", "."]
}

action "Auth Google" {
  uses = "actions/gcloud/auth@master"
  secrets = ["GCLOUD_AUTH"]
}

action "Tag image for GCR" {
  needs = ["Auth Google", "Build docker image"]
  uses = "actions/docker/tag@master"
  env = {
    PROJECT_ID = "decryptr-196601"
    APPLICATION_NAME = "api"
  }
  args = ["api", "gcr.io/$PROJECT_ID/$APPLICATION_NAME"]
}

action "Push image to GCR" {
  needs = ["Tag image for GCR"]
  uses = "actions/gcloud/cli@master"
  runs = "sh -c"
  env = {
    PROJECT_ID = "decryptr-196601"
    APPLICATION_NAME = "api"
  }
  args = ["docker push gcr.io/$PROJECT_ID/$APPLICATION_NAME"]
}
