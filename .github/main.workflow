workflow "Deploy" {
  on = "push"
  resolves = ["Build docker image"]
}

action "Build docker image" {
  uses = "actions/docker/cli@76ff57a"
  args = "[\"build\", \"-t\", \"api\", \".\"]"
}
