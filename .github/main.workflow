workflow "Deploy" {
  on = "push"
  resolves = [
    "Build docker image",
    "Auth Google",
  ]
}

action "Build docker image" {
  uses = "actions/docker/cli@76ff57a"
  args = ["build", "-t", "api", "."]
}

action "Auth Google" {
  uses = "actions/gcloud/auth@8ec8bfa"
  secrets = ["GCLOUD_AUTH"]
}
